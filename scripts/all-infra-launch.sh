#!/bin/sh
# all-infra-launch.sh

SCRIPT_DIR="$(dirname "$0")"

"$SCRIPT_DIR/nginx-launch.sh"
"$SCRIPT_DIR/plg-launch.sh"
"$SCRIPT_DIR/storage-launch.sh"

echo "All services have been started."