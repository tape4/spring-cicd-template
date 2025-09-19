# Spring 애플리케이션을 위한 CI/CD 파이프라인

이 프로젝트는 AWS EC2(For only one Free tier instance)에서 실행되는 Spring 애플리케이션을 위한 CI/CD 파이프라인을 구현합니다. 인프라는 Spring Boot, MariaDB, Nginx, Redis, Grafana, Loki, Prometheus를 포함하며, 모두 Docker를 통해 컨테이너화되어 있습니다.

## 시스템 구조

### 기본 구조
```mermaid
%%{init: {'theme': 'neutral', 'themeVariables': { 'background': '#F0F0F0' }}}%%
flowchart TD
	%% 노드에 적용할 클래스 정의
    classDef redText fill:#f8d7da,stroke:#721c24,stroke-width:2px,color:#721c24;
    classDef blueText fill:#cce5ff,stroke:#004085,stroke-width:2px,color:#004085;
    classDef external fill:#b3e5fc,stroke:#0288d1,stroke-width:2px;
    classDef nginx fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px;
    classDef app fill:#f8bbd0,stroke:#880e4f,stroke-width:2px;
    classDef monitor fill:#fff9c4,stroke:#f9a825,stroke-width:2px;
    classDef storage fill:#ffe0b2,stroke:#ef6c00,stroke-width:2px;
    classDef management fill:#d1c4e9,stroke:#5e35b1,stroke-width:2px;

    %% 외부 사용자 노드
    U[User]:::external

    %% AWS EC2 내 시스템 전체를 묶는 서브그래프
    subgraph "AWS EC2"
        %% Layer 1: Nginx
        subgraph "Layer 1: Nginx"
          N[Nginx]:::nginx
          NS[Nginx-status]:::nginx
        end

        %% Layer 2: Spring Applications
        subgraph "Layer 2: Spring Applications"
          S1["(8080:8080)<br/>Spring App #1<br/>(Running)"]:::app
          S2["(8081:8080)<br/>(Idle)"]:::app
        end

        %% Layer 3: Monitoring Services
        subgraph "Layer 3: Monitoring Services"
          P[Prometheus<br/>9090:9090]:::monitor
          G[Grafana<br/>3000:3000]:::monitor
          L[Loki<br/>3100:3100]:::monitor
        end

        %% Layer 4: storage Services
        subgraph "Layer 4: storage Services"
          R[Redis<br/>6379:6379]:::storage
          D[MariaDB<br/>3306:3306]:::storage
        end

        subgraph "Rolling Update Procedures"
            PULL("Pull Latest Images"):::management
            ROLL_UPDATE("Rolling Update Script"):::management
        end

        %% 내부 연결
        N -- "Route: /" --> S1
        N -- "Route: /: Not connected" --> S2
        N -- "Route: /status" --> NS
        N -- "Route: /grafana" --> G

        S1 -- "Metrics" --> P
        S1 -- "loki4j" --> L
        S1 -- "RefreshToken" --> R
        S1 -- "DataQuery" --> D

        P -- "MetricsFeed" --> G
	    L -- "LogFeed" --> G
    end

    U -->|HTTP Request| N
    
    linkStyle 0 stroke:#ff0000, stroke-width:5px, color:#ff0000
    linkStyle 1 stroke:#004085, stroke-width:5px, color:#004085
    linkStyle 2 stroke:#ff0000, stroke-width:5px, color:#ff0000
    linkStyle 3 stroke:#ff0000, stroke-width:5px, color:#ff0000
    linkStyle 10 stroke:#008000, stroke-width:5px, color:#000000
```

2. 업데이트 중 상태:
```mermaid
%%{init: {'theme': 'neutral', 'themeVariables': { 'background': '#F0F0F0' }}}%%
flowchart TD
	%% 노드에 적용할 클래스 정의
    classDef external fill:#b3e5fc,stroke:#0288d1,stroke-width:2px;
    classDef nginx fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px;
    classDef app fill:#f8bbd0,stroke:#880e4f,stroke-width:2px;
    classDef monitor fill:#fff9c4,stroke:#f9a825,stroke-width:2px;
    classDef storage fill:#ffe0b2,stroke:#ef6c00,stroke-width:2px;
    classDef management fill:#d1c4e9,stroke:#5e35b1,stroke-width:2px;
    
 %% 외부 사용자 노드
    U[User]:::external

    %% AWS EC2 내 시스템 전체를 묶는 서브그래프
    subgraph "AWS EC2"
        %% Layer 1: Nginx
        subgraph "Layer 1: Nginx"
          N[Nginx]:::nginx
          NS[Nginx-status]:::nginx
        end

 %% Layer 2: Spring Applications
        subgraph "Layer 2: Spring Applications"
          S1["(8080:8080)<br/>Spring App #1<br/>(Running)"]:::app
          S2["(8081:8080)<br/>Spring App #2<br/>(Updating)"]:::app
        end

        %% Layer 3: Monitoring Services
        subgraph "Layer 3: Monitoring Services"
          P[Prometheus<br/>9090:9090]:::monitor
          G[Grafana<br/>3000:3000]:::monitor
          L[Loki<br/>3100:3100]:::monitor
        end

        %% Layer 4: storage Services
        subgraph "Layer 4: storage Services"
          R[Redis<br/>6379:6379]:::storage
          D[MariaDB<br/>3306:3306]:::storage
        end

        subgraph "Rolling Update Procedures"
            PULL("Pull Latest Images"):::management
            ROLL_UPDATE("Rolling Update Script"):::management
        end

        %% 내부 연결
	N -- "Route: /" --> S1
        N -- "Route: /: Not connected" --> S2
        N -- "Route: /status" --> NS
        N -- "Route: /grafana" --> G

	S1 -- "Metrics" --> P
        S1 -- "loki4j" --> L
	S1 -- "RefreshToken" --> R
	S1 -- "DataQuery" --> D

	P -- "MetricsFeed" --> G
	L -- "LogFeed" --> G
    end

    U -->|HTTP Request| N
    
    linkStyle 0 stroke:#ff0000, stroke-width:5px, color:#ff0000
    linkStyle 1 stroke:#004085, stroke-width:5px, color:#004085
    linkStyle 2 stroke:#ff0000, stroke-width:5px, color:#ff0000
    linkStyle 3 stroke:#ff0000, stroke-width:5px, color:#ff0000
    linkStyle 10 stroke:#008000, stroke-width:5px, color:#000000
```
```mermaid
%%{init: {'theme': 'neutral', 'themeVariables': { 'background': '#F0F0F0' }}}%%
flowchart TD
	%% 노드에 적용할 클래스 정의
    classDef external fill:#b3e5fc,stroke:#0288d1,stroke-width:2px;
    classDef nginx fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px;
    classDef app fill:#f8bbd0,stroke:#880e4f,stroke-width:2px;
    classDef monitor fill:#fff9c4,stroke:#f9a825,stroke-width:2px;
    classDef storage fill:#ffe0b2,stroke:#ef6c00,stroke-width:2px;
    classDef management fill:#d1c4e9,stroke:#5e35b1,stroke-width:2px;

    %% 외부 사용자 노드
    U[User]:::external

subgraph "AWS EC2"
        %% Layer 1: Nginx
        subgraph "Layer 1: Nginx"
          N[Nginx]:::nginx
          NS[Nginx-status]:::nginx
        end

        %% Layer 2: Spring Applications
        subgraph "Layer 2: Spring Applications"
          S1["(8080:8080)<br/>Spring App #1<br/>(Running)"]:::app
          S2["(8081:8080)<br/>Spring App #2<br/>(Running)"]:::app
        end

        %% Layer 3: Monitoring Services
        subgraph "Layer 3: Monitoring Services"
          P[Prometheus<br/>9090:9090]:::monitor
          G[Grafana<br/>3000:3000]:::monitor
          L[Loki<br/>3100:3100]:::monitor
        end

        %% Layer 4: storage Services
        subgraph "Layer 4: storage Services"
          R[Redis<br/>6379:6379]:::storage
          D[MariaDB<br/>3306:3306]:::storage
        end

        subgraph "Rolling Update Procedures"
            PULL("Pull Latest Images"):::management
            ROLL_UPDATE("Rolling Update Script"):::management
        end

        %% 내부 연결
        N -- "Route: /" --> S1
        N -- "Route: /" --> S2
        N -- "Route: /status" --> NS
        N -- "Route: /grafana" --> G

        S1 -- "Metrics" --> P
        S1 -- "loki4j" --> L
        S1 -- "RefreshToken" --> R
        S1 -- "DataQuery" --> D

        S2 -- "Metrics" --> P
        S2 -- "loki4j" --> L
        S2 -- "RefreshToken" --> R
        S2 -- "DataQuery" --> D

        P -- "MetricsFeed" --> G
	    L -- "LogFeed" --> G
    end

    U -->|HTTP Request| N
    
    linkStyle 0 stroke:#ff0000, stroke-width:5px, color:#ff0000
    linkStyle 1 stroke:#ff0000, stroke-width:5px, color:#ff0000
    linkStyle 2 stroke:#ff0000, stroke-width:5px, color:#ff0000
    linkStyle 3 stroke:#ff0000, stroke-width:5px, color:#ff0000
    linkStyle 14 stroke:#008000, stroke-width:5px, color:#000000
```

3. 업데이트 후 상태:
```mermaid
%%{init: {'theme': 'neutral', 'themeVariables': { 'background': '#F0F0F0' }}}%%
flowchart TD
	%% 노드에 적용할 클래스 정의
    classDef redText fill:#f8d7da,stroke:#721c24,stroke-width:2px,color:#721c24;
    classDef blueText fill:#cce5ff,stroke:#004085,stroke-width:2px,color:#004085;
    classDef external fill:#b3e5fc,stroke:#0288d1,stroke-width:2px;
    classDef nginx fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px;
    classDef app fill:#f8bbd0,stroke:#880e4f,stroke-width:2px;
    classDef monitor fill:#fff9c4,stroke:#f9a825,stroke-width:2px;
    classDef storage fill:#ffe0b2,stroke:#ef6c00,stroke-width:2px;
    classDef management fill:#d1c4e9,stroke:#5e35b1,stroke-width:2px;
    
     %% 외부 사용자 노드
    U[User]:::external

    %% AWS EC2 내 시스템 전체를 묶는 서브그래프
    subgraph "AWS EC2"
        %% Layer 1: Nginx
        subgraph "Layer 1: Nginx"
          N[Nginx]:::nginx
          NS[Nginx-status]:::nginx
        end

        %% Layer 2: Spring Applications
        subgraph "Layer 2: Spring Applications"
          S1["(8080:8080)<br/>Spring App #1<br/>(stopping)"]:::app
          S2["(8081:8080)<br/>Spring App #2<br/>(Running)"]:::app
        end

        %% Layer 3: Monitoring Services
        subgraph "Layer 3: Monitoring Services"
          P[Prometheus<br/>9090:9090]:::monitor
          G[Grafana<br/>3000:3000]:::monitor
          L[Loki<br/>3100:3100]:::monitor
        end

        %% Layer 4: storage Services
        subgraph "Layer 4: storage Services"
          R[Redis<br/>6379:6379]:::storage
          D[MariaDB<br/>3306:3306]:::storage
        end

        subgraph "Rolling Update Procedures"
            PULL("Pull Latest Images"):::management
            ROLL_UPDATE("Rolling Update Script"):::management
        end

        %% 내부 연결
        N -- "Route: /: Not connected" --> S1
        N -- "Route: /" --> S2
        N -- "Route: /status" --> NS
        N -- "Route: /grafana" --> G

        S2 -- "Metrics" --> P
        S2 -- "loki4j" --> L
        S2 -- "RefreshToken" --> R
        S2 -- "DataQuery" --> D

	P -- "MetricsFeed" --> G
	L -- "LogFeed" --> G
    end

    U -->|HTTP Request| N
    
    linkStyle 0 stroke:#004085, stroke-width:5px, color:#004085
    linkStyle 1 stroke:#ff0000, stroke-width:5px, color:#ff0000
    linkStyle 2 stroke:#ff0000, stroke-width:5px, color:#ff0000
    linkStyle 3 stroke:#ff0000, stroke-width:5px, color:#ff0000
    linkStyle 10 stroke:#008000, stroke-width:5px, color:#000000
```

```mermaid
%%{init: {'theme': 'neutral', 'themeVariables': { 'background': '#F0F0F0' }}}%%
flowchart TD
	%% 노드에 적용할 클래스 정의
    classDef redText fill:#f8d7da,stroke:#721c24,stroke-width:2px,color:#721c24;
    classDef blueText fill:#cce5ff,stroke:#004085,stroke-width:2px,color:#004085;
    classDef external fill:#b3e5fc,stroke:#0288d1,stroke-width:2px;
    classDef nginx fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px;
    classDef app fill:#f8bbd0,stroke:#880e4f,stroke-width:2px;
    classDef monitor fill:#fff9c4,stroke:#f9a825,stroke-width:2px;
    classDef storage fill:#ffe0b2,stroke:#ef6c00,stroke-width:2px;
    classDef management fill:#d1c4e9,stroke:#5e35b1,stroke-width:2px;

    %% 외부 사용자 노드
    U[User]:::external

    %% AWS EC2 내 시스템 전체를 묶는 서브그래프
    subgraph "AWS EC2"
        %% Layer 1: Nginx
        subgraph "Layer 1: Nginx"
          N[Nginx]:::nginx
          NS[Nginx-status]:::nginx
        end

        %% Layer 2: Spring Applications
        subgraph "Layer 2: Spring Applications"
            S1["(8080:8080)<br/>(Idle)"]:::app
            S2["(8081:8080)<br/>Spring App #2<br/>(Running)"]:::app
        end

        %% Layer 3: Monitoring Services
        subgraph "Layer 3: Monitoring Services"
          P[Prometheus<br/>9090:9090]:::monitor
          G[Grafana<br/>3000:3000]:::monitor
          L[Loki<br/>3100:3100]:::monitor
        end

        %% Layer 4: storage Services
        subgraph "Layer 4: storage Services"
          R[Redis<br/>6379:6379]:::storage
          D[MariaDB<br/>3306:3306]:::storage
        end

        subgraph "Rolling Update Procedures"
            PULL("Pull Latest Images"):::management
            ROLL_UPDATE("Rolling Update Script"):::management
        end

        %% 내부 연결
        N -- "Route: /: Not connected" --> S1
        N -- "Route: /" --> S2
        N -- "Route: /status" --> NS
        N -- "Route: /grafana" --> G

        S2 -- "Metrics" --> P
        S2 -- "loki4j" --> L
        S2 -- "RefreshToken" --> R
        S2 -- "DataQuery" --> D

        P -- "DataFeed" --> G
	L -- "LogFeed" --> G
    end

    U -->|HTTP Request| N
    
    linkStyle 0 stroke:#004085, stroke-width:5px, color:#004085
    linkStyle 1 stroke:#ff0000, stroke-width:5px, color:#ff0000
    linkStyle 2 stroke:#ff0000, stroke-width:5px, color:#ff0000
    linkStyle 3 stroke:#ff0000, stroke-width:5px, color:#ff0000
    linkStyle 10 stroke:#008000, stroke-width:5px, color:#000000
```

- **Nginx**: 모든 요청 처리 및 로드 밸런싱 (Spring App 컨테이너 간)
- **Spring App**: 2개의 인스턴스로 무중단 배포를 지원
- **MariaDB & Redis**: 데이터 저장 및 캐싱
- **Prometheus & Loki**: 모니터링 및 로깅
- **Grafana**: 모니터링 대시보드

## 사용된 커스텀 Nginx 이미지

기본 Nginx 오픈소스 버전은 upstream 대상의 애플리케이션 레벨 헬스체크 기능이 내장되어 있지 않기 때문에, 이 프로젝트에서는 아래의 커스텀 이미지를 사용합니다:
- [mrlioncub/nginx_upstream_check_module (GitHub)](https://github.com/mrlioncub/nginx_upstream_check_module)
- [idscan/nginx_upstream_check_module (Docker Hub)](https://hub.docker.com/r/idscan/nginx_upstream_check_module)

이 커스텀 이미지는 NGINX를 [nginx_upstream_check_module](https://github.com/yaoweibin/nginx_upstream_check_module) 모듈과 함께 빌드한 것으로, 다음과 같은 기능을 제공합니다:

- **HTTP 상태 기반의 upstream 서버 헬스체크**
- 비정상 인스턴스 자동 제외 → 안정적인 트래픽 분산
- 무중단 롤링 업데이트 시 유용하게 작동

> **도커파일 위치**: `nginx/Dockerfile`  
> 참고: 이 모듈은 NGINX Plus에서 제공하는 기능의 오픈소스 대안입니다.


## 사전 요구사항

- AWS EC2 인스턴스(프리티어)
- Docker 및 Docker Compose 설치
- Git
- 충분한 메모리 공간(가상 메모리 설정을 권장)

## 프로젝트 구조

```
.
├── .env.template           # 환경 변수 템플릿
├── grafana/                # Grafana, Loki, Prometheus 설정
├── nginx/                  # Nginx 설정 및 Dockerfile
├── rolling_update/         # 롤링 업데이트 스크립트
├── scripts/                # 인프라 관리 스크립트
└── storage/                # MariaDB 및 Redis 설정
```

## 설정 안내

### 1. 스왑 공간 설정(프리티어에 권장)

EC2 프리티어 인스턴스의 제한된 메모리(1GB)로 인해 스왑 공간 설정이 필수입니다. 

**자동 설정:**
```bash
# 스크립트 실행 권한 부여
chmod +x scripts/setup-swap.sh

# 스왑 메모리 설정 (2GB)
sudo ./scripts/setup-swap.sh
```

**수동 설정 (선택사항):**
```bash
# 2GB 스왑 파일 생성
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 부팅 시 자동 활성화
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 스왑 사용률 조정 (메모리 90% 사용 후 스왑 사용)
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
```

**확인:**
```bash
free -h  # 메모리 상태 확인
swapon --show  # 스왑 상태 확인
```

### 2. 환경 설정

1. `.env.template`을 `.env`로 복사:
   ```bash
   cp .env.template .env
   ```

2. `.env`에서 다음 변수들을 업데이트:

   #### 프로젝트 설정
   - `PROJECT_NAME`: 프로젝트 이름 (예: myproject)
     - **중요**: 이 값은 Grafana 대시보드의 로그 쿼리에서 사용됩니다
     - Spring 애플리케이션의 로그 라벨과 일치해야 합니다

   #### Spring 애플리케이션 설정
   - `SPRING_INTERNAL_PORT`: Docker 컨테이너 내부 Spring 애플리케이션 포트 (기본값: 8080)
   - `SPRING_APP_PORT_1`: Spring App #1의 외부 노출 포트 (기본값: 8080)
   - `SPRING_APP_PORT_2`: Spring App #2의 외부 노출 포트 (기본값: 8081)


   #### Docker 이미지 설정
   - `DOCKER_ACCOUNT_ID`: Docker Hub 계정 ID
   - `DOCKER_REPOSITORY_NAME`: 애플리케이션 저장소 이름
   - `DOCKER_IMAGE_TAG`: Docker 이미지 태그 (기본값: latest)

   #### 데이터베이스 설정
   - `DB_ROOT_PASSWORD`: MariaDB 루트 비밀번호
   - `DB_NAME`: 데이터베이스 이름
   - `DB_USER`: 데이터베이스 사용자 이름
   - `DB_PASSWORD`: 데이터베이스 사용자 비밀번호
   - `DB_PORT`: MariaDB 포트 (기본값: 3306)
   - `DB_TESTDB_NAME`: 테스트 데이터베이스 이름

   #### Redis 설정
   - `REDIS_PORT`: Redis 포트 (기본값: 6379)

   #### Grafana 설정
   - `GRAFANA_PORT`: Grafana 포트 (기본값: 3000)
   - `GRAFANA_USER`: Grafana 사용자 이름
   - `GRAFANA_PASSWORD`: Grafana 비밀번호

   #### Loki 설정
   - `LOKI_PORT`: Loki 포트 (기본값: 3100)

   #### 임시 파일 설정 (수정 금지)
   - `PROMETHEUS_CONFIG_FILE`: Prometheus 설정 파일
   - `DATASOURCES_CONFIG_FILE`: Grafana 데이터소스 설정 파일
   - `DC_PROCESSED`: 처리된 Docker Compose 파일
   - `SQL_PROCESSED`: 처리된 SQL 초기화 파일
   - `NGINX_PROCESSED`: 처리된 Nginx 설정 파일

### 3. Spring 애플리케이션 속성

Spring 애플리케이션의 `application.properties` 또는 `application.yml`이 다음 환경 변수와 일치하는지 확인하세요:

```properties
# 데이터베이스 설정
spring.datasource.url=jdbc:mariadb://mariadb:3306/${DB_NAME}
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASSWORD}

# Redis 설정
spring.redis.host=redis
spring.redis.port=${REDIS_PORT}

# Prometheus 설정
management.endpoints.web.exposure.include=prometheus
management.metrics.export.prometheus.enabled=true

...

# Loki 로깅 설정 (선택사항)
logging.config=classpath:logback-spring.xml

# 주의: 위 설정들은 .env 파일의 환경 변수와 정확히 일치해야 합니다.
# DB_NAME, DB_USER, DB_PASSWORD, REDIS_PORT 등의 값이 .env 파일의 값과 동일한지 확인하세요.
# 또한 Loki 로깅을 위해 app 라벨이 PROJECT_NAME과 일치하도록 logback-spring.xml을 설정하세요.
```

## 사용법

### 권한 설정
```bash
# 스크립트 실행 권한 부여
chmod +x scripts/*.sh
chmod +x rolling_update/*.sh

# Docker 관련 권한 설정
sudo usermod -aG docker $USER
# 변경사항 적용을 위해 재로그인 필요
```

### 네트워크 설정 (최초 1회)
```bash
# 공유 Docker 네트워크 생성
./scripts/setup-network.sh
```

**참고**: 이 단계는 최초 1회만 실행하면 됩니다. 모든 인프라 서비스가 동일한 `shared_backend` 네트워크를 사용합니다.

### 인프라 관리

1. 모든 인프라 시작:
   ```bash
   ./scripts/all-infra-launch.sh
   ```

2. 모든 인프라 종료:
   ```bash
   ./scripts/all-infra-shutdown.sh
   ```

### 롤링 업데이트

애플리케이션 롤링 업데이트 실행:
```bash
./rolling_update/rolling-update.sh
```

롤링 업데이트 스크립트는 다음과 같은 작업을 수행합니다:
1. 최신 Docker 이미지를 자동으로 가져옵니다.
2. 기존 컨테이너를 순차적으로 중지하고 새로운 이미지로 교체합니다.
3. 각 단계마다 애플리케이션의 상태를 확인하여 무중단 배포를 보장합니다.

롤링 업데이트 실패 시:
- 스크립트는 새 컨테이너가 정상적으로 시작되지 않으면 배포를 중단합니다.
- 기존 컨테이너는 그대로 유지되어 서비스 중단이 발생하지 않습니다.
- 실패 로그를 확인한 후 문제를 해결하고 다시 롤링 업데이트를 시도하세요.

### 개별 구성 요소 관리

- Nginx:
  ```bash
  ./scripts/nginx-launch.sh
  ./scripts/nginx-shutdown.sh
  ```

- 스토리지(MariaDB 및 Redis):
  ```bash
  ./scripts/storage-launch.sh
  ./scripts/storage-shutdown.sh
  ```

- PLG 스택(Prometheus, Loki, Grafana):
  ```bash
  ./scripts/plg-launch.sh
  ./scripts/plg-shutdown.sh
  ```

**참고**: PLG 스택 실행 시 Grafana 대시보드가 자동으로 `.env` 파일의 `PROJECT_NAME`에 맞춰 설정됩니다. 이를 통해 로그 쿼리가 올바른 애플리케이션을 대상으로 합니다.

## 모니터링

### EC2 보안 그룹 설정
다음 포트들을 EC2 보안 그룹에서 열어주세요:

#### 웹 서비스 접근 (필수)
- 80: Nginx 웹 서버 (HTTP)

#### 데이터베이스 접근 (선택)
- ${DB_PORT}: MariaDB (기본값: 3306)
- ${REDIS_PORT}: Redis (기본값: 6379)

### 모니터링 도구 접속
- Nginx 상태 확인: `http://your-ec2-ip:80/status`
  - Spring App #1, #2의 상태 확인 가능
  - Grafana 서비스 상태 확인 가능

- Grafana 대시보드: `http://your-ec2-ip:80/grafana`
  - Prometheus 메트릭 시각화
  - Loki 로그 시각화

## CI/CD 통합

이 파이프라인은 CI/CD 플랫폼에서 `./rolling_update/rolling-update.sh` 스크립트를 실행하여 트리거될 수 있습니다.
