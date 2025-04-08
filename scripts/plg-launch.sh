#!/bin/sh
# plg-launch.sh

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

# --- 1. prometheus-config.yml 처리 ---
echo "Processing prometheus-config.yml..."
envsubst '$PROMETHEUS_PORT_1 $PROMETHEUS_PORT_2' < "$GRAFANA_DIR/prometheus-config.yml" > "$GRAFANA_DIR/$PROMETHEUS_CONFIG_FILE"
echo "Created: $GRAFANA_DIR/$PROMETHEUS_CONFIG_FILE"

# --- 2. datasources/datasources.yaml 처리 ---
echo "Processing datasources/datasources.yaml..."
envsubst '$GRAFANA_USER $GRAFANA_PASSWORD' < "$GRAFANA_DIR/datasources/datasources.yaml" > "$GRAFANA_DIR/$DATASOURCES_CONFIG_FILE"
echo "Created: $GRAFANA_DIR/$DATASOURCES_CONFIG_FILE"

# --- 3. docker-compose.yml 처리 ---
echo "Processing docker-compose.yml..."
envsubst '$PROJECT_NAME $PROMETHEUS_EXTERNAL_PORT $LOKI_PORT $GRAFANA_PORT $GRAFANA_USER $GRAFANA_PASSWORD' < "$GRAFANA_DIR/docker-compose.yml" > "$GRAFANA_DIR/$DC_PROCESSED"
echo "Created: $GRAFANA_DIR/$DC_PROCESSED"

# --- 4. 서비스가 이미 실행 중이면 종료 ---
echo "Stopping existing services (if any)..."
docker compose -f "$GRAFANA_DIR/$DC_PROCESSED" down

# --- 5. docker-compose 실행 ---
echo "Starting plg Services using processed docker-compose file..."
docker compose -f "$GRAFANA_DIR/$DC_PROCESSED" up -d

echo "plg Services started."