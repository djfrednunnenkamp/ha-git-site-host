#!/usr/bin/env bash
set -euo pipefail

CONFIG="/data/options.json"
WORKDIR="/data/repo"
PUBLISH="/data/site"

repo_url="$(jq -r '.repo_url' "$CONFIG")"
branch="$(jq -r '.branch' "$CONFIG")"
poll_interval="$(jq -r '.poll_interval' "$CONFIG")"
site_subdir="$(jq -r '.site_subdir' "$CONFIG")"
clean_on_update="$(jq -r '.clean_on_update' "$CONFIG")"
github_token="$(jq -r '.github_token // ""' "$CONFIG")"

if [[ -z "$repo_url" || "$repo_url" == "null" ]]; then
  echo "[ERROR] repo_url is empty. Configure it in the add-on UI."
  # keep running so logs show continuously
  while true; do sleep 3600; done
fi

auth_repo_url="$repo_url"
if [[ -n "$github_token" && "$repo_url" =~ ^https:// ]]; then
  # Token for private repos
  auth_repo_url="$(echo "$repo_url" | sed -E "s#^https://#https://${github_token}@#")"
fi

mkdir -p "$WORKDIR" "$PUBLISH"

do_update_now=1
trap 'do_update_now=1' USR1

clone_or_update() {
  if [[ ! -d "$WORKDIR/.git" ]]; then
    rm -rf "$WORKDIR"
    git clone --depth 1 --branch "$branch" "$auth_repo_url" "$WORKDIR"
  else
    git -C "$WORKDIR" fetch --depth 1 origin "$branch"
    git -C "$WORKDIR" reset --hard "origin/$branch"
  fi
}

publish_site() {
  local src="$WORKDIR/$site_subdir"
  if [[ ! -f "$src/index.html" ]]; then
    echo "[ERROR] index.html not found in $src"
    echo "        Make sure your repo contains a built site in '$site_subdir/' (e.g. dist/)."
    return 1
  fi

  if [[ "$clean_on_update" == "true" ]]; then
    rm -rf "${PUBLISH:?}/"*
  fi

  cp -a "$src/." "$PUBLISH/"
}

last_rev=""

while true; do
  if [[ "$do_update_now" == "1" ]]; then
    echo "[INFO] Checking repo updates..."
    do_update_now=0

    clone_or_update
    rev="$(git -C "$WORKDIR" rev-parse HEAD)"

    if [[ "$rev" != "$last_rev" ]]; then
      echo "[INFO] New revision: $rev"
      publish_site
      nginx -s reload || true
      last_rev="$rev"
      echo "[INFO] Site updated + nginx reloaded."
    else
      echo "[INFO] No changes."
    fi
  fi

  sleep "$poll_interval"
  do_update_now=1
done