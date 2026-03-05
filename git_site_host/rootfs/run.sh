#!/usr/bin/with-contenv bash
set -euo pipefail

/usr/local/bin/updater.sh &

exec nginx -g "daemon off;"