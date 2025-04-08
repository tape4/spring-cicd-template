#!/bin/sh
# nginx-launch.sh

# --- 환경 변수 로드 ---
set -a
if [ -f "$(dirname "$0")/../.env" ]; then
  echo "Loading environment variables from ../.env"
  . "$(dirname "$0")/../.env"
else
  echo "Error: ../.env file not found"
  exit 1
fi
set +a

# --- 디렉터리 변수 설정 ---
NGINX_DIR="$(dirname "$0")/../nginx"
echo "Nginx directory: $NGINX_DIR"

TARGET_DIR="/etc/nginx"
TARGET="nginx.conf"

CONTAINER_NAME="${PROJECT_NAME}-nginx"
IMAGE_NAME="${PROJECT_NAME}-nginx-healthcheck-module"

# --- nginx 설정 파일 치환 ---
echo "Processing config file: $NGINX_DIR/$TARGET"
envsubst '$SPRING_APP_PORT_1 $SPRING_APP_PORT_2 $GRAFANA_PORT $PROMETHEUS_EXTERNAL_PORT' < "$NGINX_DIR/$TARGET" > "$NGINX_DIR/$NGINX_PROCESSED"
echo "Processed config file saved as: $NGINX_DIR/$NGINX_PROCESSED"

# --- 기존 컨테이너 중지 및 제거 ---
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Container '${CONTAINER_NAME}' exists. Stopping and removing..."
  docker stop ${CONTAINER_NAME}
  docker rm ${CONTAINER_NAME}
fi

# --- 이미지 존재여부 확인 후, 없을 때만 새로 이미지 빌드 ---
if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${IMAGE_NAME}:"; then
  echo "Image '${IMAGE_NAME}' exists. Skipping build."
else
  echo "Image '${IMAGE_NAME}' does not exist. Building docker image..."
  docker build -t ${IMAGE_NAME} .
fi

# --- 컨테이너 실행 ---
echo "Starting nginx Services container: ${CONTAINER_NAME}"
docker run -d \
  --name ${CONTAINER_NAME} \
  -p 80:80 \
  -v "$NGINX_DIR/$NGINX_PROCESSED:$TARGET_DIR/$TARGET" \
  --env-file "$(dirname "$0")/../.env" \
  --add-host host.docker.internal:host-gateway \
  ${IMAGE_NAME}

echo "nginx Services started."