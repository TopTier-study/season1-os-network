# Protocol은 왜 존재할까
### 학습 키워드
* Protocol
* Network Layer
* TCP Stream
* Message Framing
* HTTP Protocol
* Network.framework

## 1. 핵심 개념

### Protocol
: **데이터를 어떻게 보내고 해석할지에 대한 규칙 집합**이다.

서로 다른 컴퓨터가 통신하려면 다음과 같은 문제를 해결해야 한다.
1. 데이터 형식은 무엇인가
2. 메시지의 시작과 끝은 어디인가
3. 데이터가 손실되면 어떻게 처리할 것인가
4. 통신 순서는 어떻게 되는가

| **요소**           | **설명**   |
|------------------|----------|
| Data Format      | 메시지 구조   |
| Message Boundary | 메시지 시작/끝 |
| Error Handling   | 오류 처리    |
| State            | 통신 상태    |

#### HTTP 형식 정의 예시
```http
GET /index.html HTTP/1.1
Host: example.com
```
-> 클라이언트와 서버가 이 형식을 **서로 약속**🤙🏻❗️🌟💖했기 때문에 통신 가능

### **프로토콜과 네트워크 계층**
네트워크는 여러 계층의 프로토콜이 함께 👯‍♂️ 동작한다. 

#### TCP/IP 모델 기준
| **Layer**    | **Protocol**    |
|--------------|-----------------|
| Application  | HTTP, DNS       |
| Transport    | TCP, UDP        |
| Network      | IP              |
| Link         | Ethernet, WiFi  |

#### 예시
`HTTP → TCP → IP → WiFi`

- 각 계층은 **자신의 역할만 담당하는 독립적 구조** (Protocol Stack)
  * HTTP - 데이터 형식 정의
  * TCP - 신뢰성 있는 전송
  * IP - 주소 기반 라우팅
  * Ethernet / WiFi - 물리 네트워크 전달
- 독립적 구조 덕분에 Application protocol은 Transport protocol과 별개로 발전 가능

> ### 정리 📢✏️🧹
> **네트워크 프로토콜 스택**: 한 장치에서 다른 장치로 전송하기 위해 사용되는 다양한 프로토콜 계층
> - 이 계층들은 서로 다른 기능을 제공
> - 각 계층은 데이터를 헤더에 추가하여 전송하고 수신 측에서는 이를 제거하면서 원래의 데이터로 복원

## 2. 탐구 내용 (실무 / iOS 연결)

### TCP는 메시지 단위를 보장하지 않는다
TCP는 **메시지 기반 통신**이 아닌 **Stream 기반 프로토콜**이다.

#### 전송 예시
```
send("Hello")
send("World")
```

#### 수신 예시
```
// 1
HelloWorld

// 2
Hel
loWo
rld
```
- 예시 2가 가능한 이유: **TCP는 **단순히 byte stream을 순서대로 전달하는 역할만 수행**** (byte stream 프로토콜)
  - 메시지 경계, send 호출 단위, packet 단위 보장 X
  - 따라서 실제 서비스에서는 **Message Framing Protocol**이 필요하다.

> ### 💭 TCP는 왜 메시지 단위가 아니라 Stream 기반일까
> - TCP 설계 목표: **신뢰성 있는 데이터 전달** ( = 성능 + 유연성)
> - TCP 내부 동작 (TCP는 네트워크 상황에 따라 데이터를 분할 / 결합하여 전송 가능)
>   - packet aggregation
>   - segmentation
>   * retransmission
> - 즉 OS가 **네트워크 상황에 맞게 packet을 재구성**함.
>   - 이때 만약 메시지 경계를 보장했다면 `packet 처리 유연성 감소`, `성능 저하`, `프로토콜 확장성 감소` 발생
> - 따라서 메시지 구조는 **Application Protocol에서 처리하도록 분리**하였다.
> - 이 구조 덕분에 다양한 프로토콜이 TCP 위에서 동작할 수 있다.

### Message Framing 방식
실제 네트워크 서버는 메시지 경계를 정의하기 위해 여러 방식을 사용한다.

#### 1) Length Prefix
메시지 길이를 먼저 보낸다. (`[length][payload]`)

- 예시: `0005 Hello`
- 장점
  * 파싱이 빠름.
  * 바이너리 데이터 지원

#### 2) Delimiter 방식
특정 구분자를 사용한다.

- 예시: 
  ```
  Hello\n
  World\n
  ```
- HTTP가 사용하는 방식

#### 3) Fixed Length
메시지 크기를 고정한다.

- 예시: `128 byte packet`
- 주로 게임 서버에서 사용

### Protocol의 진화: HTTP/3
#### 기존: **TCP 기반 HTTP** (-> 전통이었음)
```
HTTP
 |
TCP
 |
IP
```
- HTTP: **무상태(Stateless) 프로토콜** (각 요청이 독립적 = 서버가 이전 요청 정보 기억 X)
- HTTP/1.1
  - 여러 요청을 하나의 연결에서 처리 가능
  - 연결 유지(Keep-Alive) 지원
  - 요청/응답 순차 처리로 성능 한계 존재
- HTTP/2
  - 단일 연결에서 다중 요청/응답 처리 (Multiplexing)
  - 헤더 압축 -> 대역폭 절약
  - 서버 푸시(Server Push) 지원
- **문제점**
  - Head-of-line blocking (HOL Blocking)
    - 앞의 데이터가 손실되거나 지연되면 뒤에 도착한 데이터도 순서 보장을 위해 전달되지 못하고 대기하는 문제
    - TCP는 데이터 순서를 보장하기 때문에 앞선 데이터가 복구될 때까지 그 다음 데이터의 전달이 지연된다.
      - 예시) packet a, b, c 전송 중 packet b가 손실된 경우 TCP는 packet c를 받아도 전달하지 X (순서를 보장해야 하기 때문에 packet b를 재전송한 후 packet c를 전달)
- 연결 지연 (Handshake)
- 패킷 손실 시 전체 스트림 지연

#### 문제 해결: **HTTP/3 프로토콜** 🎬🛫😎
HTTP/3는 TCP 대신 **QUIC (UDP 기반 프로토콜)** 위에서 동작한다.

> - TCP (Transmission Control Protocol)
>   - 연결 지향형
>   - 신뢰성 보장 (데이터 손실 시 재전송)
>   - 순서 보장
> - UDP (User Datagram Protocol)
>   - 비연결형
>   - 데이터 손실 허용 (재전송 X)
>   - 빠른 전송 필요 시 용이

```
HTTP/3
 |
QUIC
 |
UDP
 |
IP
```

- 특징
  - QUIC 기반 프로토콜로 더 빠른 연결 설정 가능
  - 패킷 손실에도 빠른 복구 가능
  - TLS 1.3을 기본으로 채택
- 변경점
  - HTTP/3는 기존 HTTP 프로토콜을 유지(요청 - 응답 구조 유지)하면서 **Transport Layer만 변경한 구조**이다.
    - Protocol Stack 구조 덕분에 가능

### iOS에서의 Protocol Stack
```
URLSession
 |
HTTP
 |
TLS
 |
TCP
 |
IP
 |
WiFi / LTE
```

#### 1) URLSession (HTTP 중심 API)

```swift
let url = URL(string: "https://example.com")!
let task = URLSession.shared.dataTask(with: url)
task.resume()
```

- URLSession은 내부적으로 `HTTP → TLS → TCP → IP` 프로토콜 스택 사용

#### 2) Network.framework (TCP / UDP 레벨 네트워크 제어)
: iOS에서 직접 프로토콜 구현하기

- TCP / UDP 직접 사용 가능
- TLS 설정 가능
- 대표 API: `NWConnection`, `NWListener`, `NWParameters`
- 예시:
  - TCP 클라이언트
    ```swift
    let connection = NWConnection(
        host: "example.com",
        port: 9000,
        using: .tcp
    )
    
    connection.start(queue: .global())
    ```
  - 서버
    ```swift
    let listener = try NWListener(using: .tcp, on: 9000)
    
    listener.newConnectionHandler = { connection in
    connection.start(queue: .global())
    }
    ```
- 이때 개발자가 **자신만의 Application Protocol**을 정의해야 함.
  - 예: `[length][payload]`

### 보안 통신을 위한 Protocol (TLS)
HTTP 통신은 기본적으로 **평문(text) 전송**이다.
- 예시
  ```http
  GET /login
  password=1234
  ```
  - 이 데이터는 네트워크 중간에서 쉽게 노출될 수 있다.

-> 이를 해결하기 위한 프로토콜: **TLS (Transport Layer Security)**

#### TLS
: TCP 위에서 동작하는 보안 통신을 위한 프로토콜

#### TLS 동작 구조
```
HTTP
 |
TLS
 |
TCP
 |
IP
```

- **HTTPS**는 새로운 프로토콜	X, `HTTPS = HTTP + TLS`
- TLS는 handshake 과정을 통해 서버 인증 및 암호화 키 교환 수행

#### TLS 기능
- 데이터 암호화
- 서버 인증
- 데이터 무결성 보장

>iOS에서 URLSession을 사용하면 TLS가 자동으로 적용된다.

## 3. 의문 / 논점
### 1) URLSession은 실제로 몇 개의 프로토콜을 사용하고 있을까
HTTPS 요청 하나는 다음 프로토콜을 사용한다.
- HTTP
* TLS
* TCP
* IP
* WiFi

-> 즉 하나의 API 호출 뒤에서 **여러 프로토콜 계층이 동시에 동작한다.** 

### 2) 프로토콜이 없다면 어떤 문제가 발생할까
#### 예시 상황
```
Client → Hello
Server → ???
```
* 메시지 경계 파악 불가
* 데이터 해석 불가
* 통신 상태 관리 불가

-> 결과적으로 **네트워크 통신 자체가 불가능해진다.** 

## 4. 참고 자료
Computer Networking: A Top-Down Approach
[프로토콜이란?| 네트워크프로토콜 정의](https://www.cloudflare.com/ko-kr/learning/network-layer/what-is-a-protocol/)