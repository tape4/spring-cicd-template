#!/bin/bash
# setup-swap.sh - EC2 프리티어용 스왑 메모리 설정 스크립트

# 관리자 권한 확인
if [ "$EUID" -ne 0 ]; then 
    echo "이 스크립트는 sudo 권한이 필요합니다."
    echo "실행: sudo ./scripts/setup-swap.sh"
    exit 1
fi

SWAP_SIZE="2G"  # 스왑 크기 (2GB)
SWAP_FILE="/swapfile"

echo "=== EC2 프리티어 스왑 메모리 설정 시작 ==="

# 1. 현재 메모리 상태 확인
echo "현재 메모리 상태:"
free -h
echo ""

# 2. 기존 스왑 파일이 있는지 확인
if [ -f "$SWAP_FILE" ]; then
    echo "기존 스왑 파일이 발견되었습니다. 제거 중..."
    swapoff $SWAP_FILE
    rm -f $SWAP_FILE
fi

# 3. 스왑 파일 생성
echo "스왑 파일 생성 중... (크기: $SWAP_SIZE)"
fallocate -l $SWAP_SIZE $SWAP_FILE

# fallocate가 실패하면 dd 명령 사용
if [ $? -ne 0 ]; then
    echo "fallocate 실패. dd 명령으로 재시도 중..."
    dd if=/dev/zero of=$SWAP_FILE bs=1024 count=2097152
fi

# 4. 스왑 파일 권한 설정
echo "스왑 파일 권한 설정 중..."
chmod 600 $SWAP_FILE

# 5. 스왑 영역 설정
echo "스왑 영역 설정 중..."
mkswap $SWAP_FILE

# 6. 스왑 활성화
echo "스왑 활성화 중..."
swapon $SWAP_FILE

# 7. 영구 설정을 위해 /etc/fstab에 추가
if ! grep -q "$SWAP_FILE" /etc/fstab; then
    echo "부팅 시 자동 활성화를 위해 /etc/fstab에 추가 중..."
    echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
fi

# 8. 스왑 사용률 조정 (선택사항)
echo "스왑 사용률 조정 중..."
sysctl vm.swappiness=10

# 영구 설정
if ! grep -q "vm.swappiness=10" /etc/sysctl.conf; then
    echo "vm.swappiness=10" >> /etc/sysctl.conf
fi

# 9. 결과 확인
echo ""
echo "=== 스왑 메모리 설정 완료 ==="
echo "설정 후 메모리 상태:"
free -h
echo ""
echo "스왑 상세 정보:"
swapon --show
echo ""
echo "스왑 설정이 완료되었습니다!"
echo "재부팅 후에도 자동으로 활성화됩니다."