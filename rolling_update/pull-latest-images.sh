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
IMAGE_NAME="$DOCKER_ACCOUNT_ID/$DOCKER_REPOSITORY_NAME:${DOCKER_IMAGE_TAG}"

# Pull the latest image from DOCKER HUB
echo "Pull the latest image from DOCKER HUB"
docker pull $IMAGE_NAME


# docker run -d -p 8081:8080 905418199107.dkr.ecr.ap-northeast-2.amazonaws.com/spring-cd-test
# sudo ./nginx -s reload
# sudo ./nginx -t
# sudo lsof -t -i :8081
# sudo kill -15 45941