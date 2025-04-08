#!/bin/sh
# nginx-shutdown.sh

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

TARGET="nginx.conf"
CONTAINER_NAME="${PROJECT_NAME}-nginx"

# --- 기존 컨테이너 정지 및 제거 ---
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Stopping nginx Services container: ${CONTAINER_NAME}"
  docker stop ${CONTAINER_NAME}
  echo "Removing nginx Services container: ${CONTAINER_NAME}"
  docker rm ${CONTAINER_NAME}
else
  echo "No container named '${CONTAINER_NAME}' found."
fi

# --- 임시 처리된 파일 제거 ---
echo "Removing temporary processed files..."
rm -f "$NGINX_DIR/$NGINX_PROCESSED"

echo "nginx Services stopped and temporary files removed."