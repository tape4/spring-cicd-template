#!/bin/sh
# all-infra-launch.sh

./nginx-launch.sh
./plg-launch.sh
./storage-launch.sh

echo "All services have been started."