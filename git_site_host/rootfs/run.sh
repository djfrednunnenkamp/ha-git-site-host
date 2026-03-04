#!/usr/bin/with-contenv bash
set -euo pipefail

/usr/local/bin/updater.sh &
UPDATER_PID=$!

WEBHOOK_ENABLED="$(jq -r '.webhook_enabled // false' /data/options.json)"
if [[ "$WEBHOOK_ENABLED" == "true" ]]; then
  export UPDATER_PID
  /usr/local/bin/webhook_server.py &
fi

exec nginx -g "daemon off;"