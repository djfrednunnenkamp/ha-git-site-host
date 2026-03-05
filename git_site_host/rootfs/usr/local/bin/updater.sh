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
  while true; do sleep 3600; done
fi

auth_repo_url="$repo_url"
if [[ -n "$github_token" && "$repo_url" =~ ^https:// ]]; then
  auth_repo_url="$(echo "$repo_url" | sed -E "s#^https://#https://${github_token}@#")"
fi

mkdir -p "$WORKDIR" "$PUBLISH"

do_update_now=1
trap 'do_update_now=1' USR1

get_remote_head() {
  # returns commit hash of branch head
  git ls-remote --heads "$auth_repo_url" "$branch" | awk '{print $1}'
}

get_local_head() {
  if [[ -d "$WORKDIR/.git" ]]; then
    git -C "$WORKDIR" rev-parse HEAD 2>/dev/null || true
  fi
}

clone_or_update() {
  if [[ ! -d "$WORKDIR/.git" ]]; then
    rm -rf "$WORKDIR"
    git clone --depth 1 --branch "$branch" "$auth_repo_url" "$WORKDIR"
  else
    git -C "$WORKDIR" fetch --depth 1 origin "$branch"
    git -C "$WORKDIR" reset --hard "origin/$branch"
  fi
}

publish_site_atomic() {
  local src="$WORKDIR/$site_subdir"
  if [[ ! -f "$src/index.html" ]]; then
    echo "[ERROR] index.html not found in $src"
    echo "        Make sure your repo contains a built site in '$site_subdir/' (e.g. dist/)."
    return 1
  fi

  # staging dir inside /data so rename is atomic
  local tmp
  tmp="$(mktemp -d /data/site_tmp.XXXXXX)"
  cp -a "$src/." "$tmp/"

  # optional cleanup (kept for compatibility)
  if [[ "$clean_on_update" == "true" ]]; then
    :
  fi

  # Atomic swap: rename dirs (fast and avoids partial state)
  local prev="/data/site_prev"
  rm -rf "$prev" || true

  if [[ -d "$PUBLISH" ]]; then
    mv "$PUBLISH" "$prev"
  fi

  mv "$tmp" "$PUBLISH"

  rm -rf "$prev" || true
  echo "[INFO] Site published (atomic)."
}

last_remote_rev=""

while true; do
  if [[ "$do_update_now" == "1" ]]; then
    echo "[INFO] Checking repo updates..."
    do_update_now=0

    remote_rev="$(get_remote_head || true)"

    if [[ -z "$remote_rev" ]]; then
      echo "[ERROR] Could not read remote HEAD. Check repo_url/branch."
    elif [[ "$remote_rev" == "$last_remote_rev" ]]; then
      echo "[INFO] No changes. Skipping."
    else
      echo "[INFO] New revision: $remote_rev"
      clone_or_update

      # local head after update
      local_rev="$(get_local_head)"
      echo "[INFO] Local revision: ${local_rev:-unknown}"

      publish_site_atomic
      nginx -s reload || true

      last_remote_rev="$remote_rev"
      echo "[INFO] Site updated + nginx reloaded."
    fi
  fi

  sleep "$poll_interval"
  do_update_now=1
done