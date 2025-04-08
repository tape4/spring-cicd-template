#!/bin/sh
# storage-shutdown.sh

# --- 환경 변수 로드 ---
if [ -f "$(dirname "$0")/../.env" ]; then
  echo "Loading environment variables from ../.env"
  set -a
  . "$(dirname "$0")/../.env"
  set +a
else
  echo "Error: ../.env file not found"
  exit 1
fi

# --- 디렉터리 변수 설정 ---
STORAGE_DIR="$(dirname "$0")/../storage"

# --- 1. docker-compose 서비스 종료 ---
echo "Stopping storage Services using processed docker-compose file..."
docker compose -f "$STORAGE_DIR/$DC_PROCESSED" down

# --- 2. 임시 처리된 파일 제거 ---
echo "Removing temporary processed files..."
rm -f "$STORAGE_DIR/$SQL_PROCESSED"
rm -f "$STORAGE_DIR/$DC_PROCESSED"

echo "storage Services stopped and temporary files removed."