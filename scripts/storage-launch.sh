#!/bin/sh
# storage-launch.sh

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

# --- 1. init.sql 템플릿 처리 ---
echo "Processing init.sql..."
envsubst '$DB_NAME $DB_USER $DB_PASSWORD $DB_TESTDB_NAME' < "$STORAGE_DIR/init.sql" > "$STORAGE_DIR/$SQL_PROCESSED"
echo "Created: $STORAGE_DIR/$SQL_PORCESSED"

# --- 2. docker-compose.yml 처리 ---
echo "Processing docker-compose.yml..."
envsubst '$PROJECT_NAME $PROMETHEUS_EXTERNAL_PORT $LOKI_PORT $GRAFANA_PORT $GRAFANA_USER $GRAFANA_PASSWORD' < "$STORAGE_DIR/docker-compose.yml" > "$STORAGE_DIR/$DC_PROCESSED"
echo "Created: $STORAGE_DIR/$DC_PROCESSED"

# --- 3. 서비스가 이미 실행 중이면 종료 ---
echo "Stopping existing services (if any)..."
docker compose -f "$STORAGE_DIR/$DC_PROCESSED" down

# --- 4. docker-compose 실행 ---
echo "Starting storage Services using processed docker-compose file..."
docker compose -f "$STORAGE_DIR/$DC_PROCESSED" up -d

echo "storage Services started."