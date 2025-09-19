#!/bin/bash

# Load environment variables
if [ -f "$(dirname "$0")/../.env" ]; then
  source "$(dirname "$0")/../.env"
else
  echo "Error: .env file not found"
  exit 1
fi

# idle 포트 찾기
function check_ports_idle
{
  ports=(${SPRING_APP_PORT_1} ${SPRING_APP_PORT_2})
  available=()
  echo "Checking port availability..."
  for port in "${ports[@]}"
  do
      # 체크할 포트
      check_port="$port"
      echo "check port $check_port"

      # 포트 상태 확인
      ss -lnt | awk '$4 ~ /^.*:'"$check_port"'$/ {exit 1}'
      if [ $? -eq 0 ]; then
          available+=("$check_port")
      fi

  done
  echo ${available[@]}
}

# 사용중인 포트 찾기
function check_ports_in_use
{
  ports=(${SPRING_APP_PORT_1} ${SPRING_APP_PORT_2})

  in_use=()
  echo "Checking port availability..."
  for port in "${ports[@]}"
  do
      # 체크할 포트
      check_port="$port"
      echo "check port $check_port"

      # 포트 상태 확인
      ss -lnt | awk '$4 ~ /^.*:'"$check_port"'$/ {exit 1}'
      if [ $? -ne 0 ]; then
          in_use+=("$check_port")
      fi

  done
  echo ${in_use[@]}
}

function switch_container()
{

  # Docker Hub 에서 새로운 이미지 받기
  source "$(dirname "$0")/pull-latest-images.sh"

  start_new_container

  is_container_update_done="false"
  for i in {0..5}
  do
    # 새로운 컨테이너가 떴다면
    if [ "$(is_new_container_running)" == "true" ]; then
      echo "New container has been detected. Stopping old container..."
      is_container_update_done="true"
      restart_redis
      break
    else
      echo "No new container has been detected. Retrying in 10 seconds..."
    fi
    sleep 10
  done

  # 새로운 컨테이너가 실행 중인지 확인
  if [ "$is_container_update_done" == "true" ]; then
    stop_old_container
  else
    echo "Update failed."
    exit 1
  fi
}

# 새로운 컨테이너의 /health-check 응답 코드를 확인하는 스크립트
function is_new_container_running() {

  idle_port=${idle_ports[0]}
  response_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$idle_port/actuator/health)

  if [[ $response_code -ge 200 && $response_code -lt 300 ]]; then
    echo "true"
  else
    echo "false"
  fi
}

function restart_redis() {
  echo "Flushing redis container data..."
  redis_container_name="${PROJECT_NAME}-redis"
  if docker exec $redis_container_name redis-cli FLUSHALL; then
    echo "Redis container data flushed successfully."
  else
    echo "Failed to flush Redis container data."
    exit 1
  fi
}

function start_new_container() {
  idle_port=${idle_ports[0]} # idle 포트
  
  echo "Starting container using port $idle_port..."
  docker run -d --name "${PROJECT_NAME}-spring-container-${idle_port}" \
    -p $idle_port:${SPRING_INTERNAL_PORT} \
    --network shared_backend \
    --add-host host.docker.internal:host-gateway \
    $IMAGE_NAME
}

function stop_old_container() {
  if [ ${#use_ports[@]} -eq 0 ]; then
    echo "There's no running container to stop"
    return
  fi

  use_port=${use_ports[0]} # 사용중인 포트

  # 포트로 매핑된 사용 중인 컨테이너 ID 찾기
  container_id=$(docker ps --filter "publish=$use_port" --format "{{.ID}}")

  if [ -n "$container_id" ]; then
      echo "Stopping container $container_id using port $use_port..."
      docker stop "$container_id"
  else
      echo "No container is using port $use_port."
  fi
}

use_ports=($(check_ports_in_use | tail -n 1))
idle_ports=($(check_ports_idle | tail -n 1))

switch_container

# Remove last server version image
echo "Remove last server version image"
docker rm $(docker ps -a -f status=exited -q)
docker image prune -f