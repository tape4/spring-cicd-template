#!/bin/sh
# all-infra-shutdown.sh

./nginx-shutdown.sh
./plg-shutdown.sh
./storage-shutdown.sh

echo "All services have been shut down."