#!/bin/sh
# all-infra-shutdown.sh

SCRIPT_DIR="$(dirname "$0")"

"$SCRIPT_DIR/nginx-shutdown.sh"
"$SCRIPT_DIR/plg-shutdown.sh"
"$SCRIPT_DIR/storage-shutdown.sh"

echo "All services have been shut down."