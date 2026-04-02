# **Optimizing Your App for Today’s Internet**

## 1. 시청한 WWDC 영상

- [**Optimizing Your App for Today’s Internet**](https://nonstrict.eu/wwdcindex/wwdc2018/714/?t=1455)

## 2. 내용 요약

### 한 문장 요약

- 당시(2018년도) 인터넷 환경에서 앱을 최적화하는 여러 방법 소개

---

### 오늘날 인터넷 환경과 기본 관점

- 전 세계 인터넷 사용자 수는 약 40억 명으로, 전 인구의 절반 이상.
- LTE/5G뿐 아니라, 여전히 2G를 쓰는 사용자도 많기 때문에 **“빠른 네트워크에서만 잘 돌아가는 앱”은 실패**할 수 있음.
- **Worldwide Internet 환경을 모의하는 도구**
    - **Network Link Conditioner**를 항상 사용하라고 권장.
    - 처음부터 테스트용으로 넣어두고, 마지막 단계에 “성능”을 뒤늦게 붙이려고 하지 말 것.
- **Wireshark, tcptrace** 등으로 네트워크 패킷 모니터링
    - **Instruments**로 CPU·메모리를 보는 것처럼, 네트워크 성능을 지속적으로 모니터링하라고 강조

---

### IPv6, ECN, TCP Fast Open, MPTCP

#### IPv6 권장

- IPv6 사용이 계속 증가 중이며, IPv6가 IPv4보다 **연결 성능이 더 좋음**
    - 인도 셀룰러 네트워크에서 TCP 연결 설정 시간 기준,
        - IPv6: 75th percentile이 약 **150ms**
        - IPv4: 75th percentile이 약 **325ms** 이상 → 약 **2배 이상 느림**
- 따라서 앱뿐만 아니라 앱이 통신하는 서비스도 **네이티브 IPv6 지원** 여부를 반드시 확인할 것

#### Explicit Congestion Notification (ECN)

- TCP의 혼잡(congestion)을 더 섬세하게 알리기 위한 기술.
- **macOS/iOS에서 이미 기본 활성화**되어 있어, 앱이 별도로 처리하지 않아도 됨
- 다만 **서버 쪽에서 ECN을 지원**해야 하므로, 서버 운영자에게 확인 필요.

#### Multipath TCP (MPTCP)

- Wi‑Fi ↔LTE망 전환 시에도 **기존 TCP 연결을 끊지 않고 다른 인터페이스로 전환**할 수 있게 해주는 기술.
- 전통적인 TCP는 인터페이스 변경 시 **연결 끊기 → 재연결 → 데이터 재전송**을 요구하지만,MPTCP는 **패킷 단위 라우팅 전환**으로 연결을 유지.
- 앱 쪽에서도 **MPTCP를 활용하는 서버 구축**을 권장.

#### TCP Fast Open

- TCP 3‑way handshake에서 발생하는 왕복 지연을 줄이기 위해
    - **초기 SYN 패킷에 데이터를 함께 실어 보내는 기술**.
- 서버가 TCP Fast Open을 지원하면, 연결 설정과 첫 요청이 합쳐져 **지연 감소**.
- 서버 운영자와 확인해 서버가 TFOL(Fast Open)을 지원하는지 확인할 것.

---

### DNS 및 Happy Eyeballs, 연결 지연 감소

#### DNS TTL을 너무 짧게 잡는 문제

- 많은 서비스가 **DNS TTL을 매우 짧게** 설정하여 데이터 센터 장애 시 빠르게 다른 IP로 전환하려 함.
- 하지만 데이터 센터 다운은 **매우 드문 이벤트**이고,
    - 그 대신 **DNS TTL 만료 시마다 추가 왕복 지연(DNS 쿼리)**이 발생.
- 이로 인해 **일반 사용자**에게는 성능 비용이 큰 편.

### OS 쪽 DNS 최적화 (Happy Eyeballs + 응용)

- 새로운 행동 패턴:
    - OS에서 **캐시에 오래된 DNS 응답이 있어도 “과거에 사용하던 주소”를 즉시 클라이언트에 전달**.
    - 동시에 **정상적인 DNS 쿼리를 별도로 수행**해 결과가 같은지 확인.
        - 같으면: 기존 주소로 바로 연결 시작 → 왕복 지연 절약.
        - 다르면: 새로운 주소로 비동기로 알림을 보내 재시도.
- 이 기능은 **Happy Eyeballs 알고리즘**과 함께 사용하는 것을 권장
    - Happy eyeballs: 듀얼스택 호스트에서 더 빠른 IP 주소를 선택하는 방법
    - IPv4/IPv6, 여러 IP, 여러 인터페이스를 **병렬로 시도**해 가장 빠른 연결을 선택.
- **Apple의 URLSession/Network 프레임워크는** 위 로직을 시스템이 자동으로 처리

---

### 네트워크 API 선택: BSD 소켓 vs URLSession vs Network.framework

#### BSD 소켓은 최대한 피하라

- 30년 전 기준으로는 우수한 API였지만,
    - 모바일, 무선, 배터리, IPv6, 다중 인터페이스, 절전 모드, 네트워크 전환 등 **오늘날의 환경을 고려하면 너무 낮은 추상화 레벨**.
- 앱은 **BSD 소켓을 직접 사용하지 말고, 더 높은 레벨의 API를 사용할 것**을 강력히 권장.

#### URLSession은 여전히 최상위 권장 API

- **URLSession**은:
    - HTTP/2, HTTP/1.1, HTTPS, 쿠키, 캐시, 인증, 프록시 등을 모두 처리하는 **높은 수준의 네트워크 API**.
    - `URLSessionStreamTask`를 통해 **HTTP가 아닌 임의의 TCP 프로토콜**도 구축 가능.

#### Network.framework 소개

- `URLSession`은 내부적으로 **Network.framework**를 사용해 구현돼 있음.
- **iOS 12 / macOS Mojave부터 Apple이 Network.framework를 공개 API로 제공**:
    - 동일한 고성능 유저스페이스 네트워크 스택을 **직접 사용**할 수 있음.
    - TCP/UDP/QUIC 등 다양한 전송 프로토콜을 직접 제어할 수 있음.
- **BSD 소켓을 래핑한 라이브러리**를 사용 중이라면:
    - Network.framework로 이동하는 것을 권장.
- **고급 네트워킹/고성능 라이브러리 개발자**는 이 프레임워크를 활용해 성능을 높일 수 있음

---

### SCNetworkReachability vs `waitsForConnectivity`

#### SCNetworkReachability의 한계

- 많은 개발자들이 `SCNetworkReachability`를 사용해 **“지금 네트워크가 연결됐는지” 사전 체크**를 함.
- 하지만:
    - 현재 연결돼 있더라도, **요청을 보낼 때 이미 네트워크가 끊어진 경우(레이스 컨디션)** 발생 가능.
    - 결과적으로는 **사전 체크 + 실패 시 재시도 루프**가 반복되어, 처리가 복잡해짐.

#### `waitsForConnectivity` 권장

- URLSession에서 도입된 **`waitsForConnectivity`** 옵션:
    - 네트워크가 없을 때 **즉시 실패하지 않고, 시스템이 연결가능해질 때까지 대기**.
    - 연결이 회복되면 **자동으로 요청을 전송**.
- 이 방식은:
    - 개발자가 **직접 재시도 루프를 구현하는 것보다 간단하고 안정적**.
    - `task.isWaitingForConnectivity` delegate를 통해 **사용자에게 “대기 중” UI/오프라인 UI**를 제공할 수 있음

---

### 보안: TLS 1.3, Certificate Transparency

#### TLS 1.3

- TLS 1.3 장점:
    - 핸드셰이크 단계가 줄어 **연결 설정 지연 감소**.
    - 여러 보안 기능이 향상됨.

#### Certificate Transparency (인증서 투명성)

- 인증서 발급 기관(CA)이 **악의/오류로 인한 부적절한 인증서 발급**을 방지하기 위한 기술.
- CA는 **모든 발급한 인증서를 공개 로그에 기록**하고,
    - 클라이언트는 그 **로그에 등록된 인증서**만 유효한 것으로 간주.
- 서버는 인증서와 함께 **로그에 등록되었음을 증명하는 서명된 데이터**를 클라이언트에 전달.
- **악성 CA가 기록을 로그에 남기지 않으면**, 클라이언트가 이를 거부.
- 2018년 이후 **새로 발급되는 TLS 인증서는 Certificate Transparency 로그 기록**이 필수.
    - 앱은 변경 없지만, **커스텀 인증서를 운영 중이라면 CA가 로그에 기록하는지 확인**할 것

---

### URLSession을 이용한 성능 최적화

#### 지연 시간 감소 (Latency Reduction)

- **HTTP/1.1의 문제**:
    - 여러 요청을 위해 **동일 서버에 여러 연결을 열면**,
        - DNS, TCP, TLS 설정 오버헤드가 반복 발생.
    - 반대로 **단일 연결 사용 시**,
        - 여러 요청이 **순서대로 대기** → **Head‑of‑line blocking(HOL blocking)**.
- **HTTP/2가 해결**:
    - 단일 TCP 연결에서 **여러 HTTP 스트림을 다중화**해
        - 여러 요청·응답을 병렬로 처리.
    - HTTP/2는 **헤더 압축(HPACK)**을 통해 데이터 크기와 왕복 지연을 모두 줄임.
    - 클라이언트 측에서는 **URLSession 사용 시** HTTP/2는 **서버측에서만 활성화**하면 자동으로 설정

#### HTTP/2 Connection Coalescing (연결 통합)

- **기존 동작**:
    - 예: `menu.example.com`, `delivery.example.com`에 대해 각각 별도의 연결을 열고, 각각 TLS 인증.
- **iOS 12 / macOS Mojave에서 HTTP/2 connection coalescing**:
    - 두 서버가 **동일 IP + 동일 증명서(예: `example.com` 와일드카드 인증서)**를 사용하면,
        - 두 도메인 사이에 **새 연결을 열지 않고 기존 연결을 재사용**.
    - 효과:
        - DNS/TLS/연결 설정 오버헤드 감소 → 지연 시간 감소.
        - 서버 측 연결 수 감소 → 비용 절감.

#### URLSession 객체 수 최소화

- **URLSession에는 자체 연결 풀이 존재**
    - 같은 `URLSession` 객체 내에서 생성된 `URLSessionTask`들은 연결을 공유하고 재사용.
- 여러 개의 `URLSession` 객체를 만들면
    - 각각 별도의 연결 풀이 생겨 **연결 재사용 이점이 사라짐**.
    - `URLSession` 객체는 **생성 비용 및 메모리 사용량이 큼**.
- 앱 내에서 **최소한의 URLSession 객체**를 공유 사용해 **지연 감소 + 메모리·자원 절약**

---

### 처리량 극대화 (Throughput / Request Size 감소)

- **요청 크기를 줄이면**:
    - 네트워크 지연·대역폭을 더 효율적으로 사용.
    - 특히 모바일/느린 네트워크에서 큰 이익

#### 쿠키 최적화

- HTTP 쿠키는 **무료가 아니며**, 서버/클라이언트 양쪽에 저장·조회 비용이 큼.
- 같은 도메인/경로에 대한 모든 요청에 자동으로 쿠키가 붙으므로,
    - **불필요하거나 큰 쿠키**는 저장하지 않거나,
    - **서버에 일부 상태를 저장**해 클라이언트 쿠키 수를 줄일 것.
- HTTP/2의 헤더 압축(HPACK)을 활용하려면 **HTTP/2 전환**을 고려

#### HTTP 압축 (Gzip, Brotli)

- **콘텐츠 압축**으로 서버↔클라이언트 간 **데이터 전송량 감소**.
- URLSession이 추천하는 방식:
    - **Gzip**: 널리 지원, 비교적 빠름.
    - **Brotli**: HTML/구조화된 텍스트에 최적화, 특히 작은 데이터에서 **압축률이 우수**.
    - Brotli는 iOS 11 / macOS High Sierra에서 추가 지원.
- 서버에서 **Gzip/Brotli 압축 활성화**를 권장

---

### 응답성 향상 (Responsiveness)

- **QoS(Quality of Service) 활용**:
    - `Dispatch`/`NSOperation`의 QoS는 **CPU 스케줄링 정책**을 의미.
    - `URLSession`은 **`task.resume()`을 호출하는 큐의 QoS**를 캡처하고, 내부에서 이를 존중.
    - 예: 백그라운드 QoS를 사용해 **대용량 데이터 페치**를 수행하면,
        - 포그라운드 작업이 CPU를 차지하지 않도록 제어

#### 네트워크 서비스 유형 (Network Service Type)

- `URLSessionConfiguration`에 `networkServiceType` 프로퍼티:
    - 네트워크 트래픽을 **분류해 시스템이 우선순위**를 정할 수 있음.
- 2018년에 **`responsiveData`** 타입 추가:
    - 기본보다 **약간 높은 우선순위**.
    - 예: **쇼핑 앱에서 결제 요청**처럼 사용자 경험에 매우 중요한 요청에 사용.
    - 일부 네트워크 장비(Cisco Fast Lane 등)는 이 태그를 각 홉에서 전달.

---

### 시스템 자원의 효율적 활용 (Resource Efficiency)

#### 백그라운드 세션

- **백그라운드 URLSession 세션**은:
    - 큰 파일 다운로드/업로드를 시스템 스케줄러에 위임해,
    - **배터리, CPU, Wi‑Fi 상태, 네트워크 요금제** 등을 고려해 **무엇을 언제 전송할지 자동 조절**함.
- 이 세션은:
    - 앱이 **사용자가 안 쓰는 상태일 때**, 혹은 **프로세스가 종료/일시중지된 상태에서**도 다운로드를 계속 진행.
    - 사용자에게는 “백그라운드에서 자동으로 받아서 준비됨”이라는 경험을 제공.
- **큰 파일**(예: 동영상, 콘텐츠 패키지, 업데이트 파일)을 가져올 때는 백그라운드 세션 사용을 권장.

#### 캐싱 최적화

- **캐싱**은 지연을 줄이는 매우 효과적인 방법이지만,
    - **디스크 IO 비용**을 간과하면 반대 효과가 생길 수 있음.
    - 실제로는 **하루 수 기가바이트 단위의 캐시를 쓰는 앱**이 관찰돼, 플래시 저장소에 **과도한 쓰기/마모**를 초래할 수 있음.
- **고유/불확실한 콘텐츠 캐싱은 피할 것**:
- **캐싱 전략**:
    - `URLSession`의 `delegate`에서:
        - `URLSessionTaskDelegate`의 `URLSession(task:willCacheResponse:completionHandler:)`를 사용해
            - 어떤 응답을 캐시할지 **클라이언트 측에서 필터링** 가능.
    - 서버 쪽에서:
        - `Cache‑Control` 헤더를 적절히 설정해 **공유/비공유, TTL, 재검증 정책**을 명시.
        - 예: `Cache‑Control: public, max‑age=3600`처럼,
            - 브라우저/프록시/클라이언트 캐시를 동시에 활용.

---

### 네트워크 프레임워크와 미래 방향

- **Network.framework**:
    - `URLSession`이 내부에서 사용하는 **고성능 유저스페이스 네트워크 라이브러리**.
    - iOS 12 / macOS Mojave에서 **퍼블릭 API로 제공**되어,
        - TCP/UDP/QUIC 등 **고급/맞춤형 네트워킹**을 구현할 수 있음.
    - 특히 **고성능 네트워크 라이브러리 개발자** 또는 **게임/멀티미디어 실시간 통신** 앱에 유용.agnosticdev+2
- **QUIC / HTTP/3**:
    - 발표에서는 **QUIC**를 “TCP를 대체할 수 있는 최초의 진지한 후보 전송 프로토콜”로 소개.
    - Apple도 **IETF 표준화 과정에 참여**하고 있으며,
        - 将来에는 **URLSession/Network.framework에서 HTTP/3를 지원**하겠다는 의도를 암시.
    - 앱 개발자는 **네트워크 로직을 하드코딩하지 말고**,
        - **URLSession/Network 프레임워크** 같은 고수준 API를 사용해,
        - 프로토콜이 바뀌어도 **최소한의 코드 변경**으로 대응되도록 설계.

---

## 3. 준비한 질문

## 4. 토론 / 공유 내용 정리
