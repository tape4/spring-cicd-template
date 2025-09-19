#!/bin/bash

# Load environment variables
if [ -f "$(dirname "$0")/../.env" ]; then
  source "$(dirname "$0")/../.env"
else
  echo "Error: .env file not found"
  exit 1
fi

# Variables
DOCKER_ACCOUNT_ID="${DOCKER_ACCOUNT_ID}"
DOCKER_REPOSITORY_NAME="${DOCKER_REPOSITORY_NAME}"
export IMAGE_NAME="$DOCKER_ACCOUNT_ID/$DOCKER_REPOSITORY_NAME:${DOCKER_IMAGE_TAG}"

# Pull the latest image from DOCKER HUB
echo "Pull the latest image from DOCKER HUB"
docker pull $IMAGE_NAME
