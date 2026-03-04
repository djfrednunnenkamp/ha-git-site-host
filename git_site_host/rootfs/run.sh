#!/usr/bin/with-contenv bash
set -euo pipefail

# Start updater (git pull loop)
 /usr/local/bin/updater.sh &
UPDATER_PID=$!

# Start webhook server (optional)
WEBHOOK_ENABLED="$(jq -r '.webhook_enabled // false' /data/options.json)"
if [[ "$WEBHOOK_ENABLED" == "true" ]]; then
  export UPDATER_PID
  /usr/local/bin/webhook_server.py &
fi

# Run nginx in foreground
nginx -g "daemon off;"