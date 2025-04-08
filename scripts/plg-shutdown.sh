#!/bin/sh
# plg-shutdown.sh

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
GRAFANA_DIR="$(dirname "$0")/../grafana"
echo "Grafana directory: $GRAFANA_DIR"

# --- 1. docker-compose 서비스 종료 ---
echo "Stopping plg Services using processed docker-compose file..."
docker compose -f "$GRAFANA_DIR/$DC_PROCESSED" down

# --- 2. 임시 처리된 파일 제거 ---
echo "Removing temporary processed files..."
rm -f "$GRAFANA_DIR/$PROMETHEUS_CONFIG_FILE"
rm -f "$GRAFANA_DIR/$DATASOURCES_CONFIG_FILE"
rm -f "$GRAFANA_DIR/$DC_PROCESSED"

echo "plg Services stopped and temporary files removed."