#!/bin/bash
# setup-network.sh - 공유 Docker 네트워크 생성 스크립트

NETWORK_NAME="shared_backend"

echo "=== Docker 네트워크 설정 ==="

# 네트워크가 이미 존재하는지 확인
if docker network ls --format "{{.Name}}" | grep -q "^${NETWORK_NAME}$"; then
    echo "네트워크 '${NETWORK_NAME}'가 이미 존재합니다."
else
    echo "네트워크 '${NETWORK_NAME}' 생성 중..."
    docker network create ${NETWORK_NAME}
    
    if [ $? -eq 0 ]; then
        echo "네트워크 '${NETWORK_NAME}' 생성 완료!"
    else
        echo "네트워크 생성 실패!"
        exit 1
    fi
fi

echo ""
echo "현재 Docker 네트워크 목록:"
docker network ls

echo ""
echo "네트워크 설정이 완료되었습니다!"
echo "이제 인프라 서비스들을 시작할 수 있습니다."