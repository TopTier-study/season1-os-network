# 전송 계층은 왜 존재할까
### 학습 키워드
- Transport Layer
* TCP / UDP
* IP
* Reliability
* Flow Control / Congestion Control
* End-to-End Principle

## 1. 핵심 개념
### 1) IP의 한계
IP는 **단순 전달 계층**이다.
(비신뢰성, 비연결형)

* **Best-effort delivery** (도착 보장 없음)
* **순서 보장 없음**
* **중복 가능**
* **속도 조절 없음**

-> 즉 IP만으로는 정상적인 데이터 통신이 불가능하다.

> #### 그럼 왜 IP는 비신뢰성, 비연결형 특징의 통신만 수행하는가?
> -> ‘성능’ 때문!
> (신뢰성 있고 사전 연결이 필수적인 통신이 마냥 좋은 것만은 아님. 이 과정들 때문에 성능이 떨어질 수도 있기 때문)

### 2) 전송 계층의 역할
전송 계층은 IP 위에서 다음을 해결한다:

#### 1.  신뢰성 (Reliability)
* 데이터가 **유실되면 재전송**
  * 일련번호(송신 측이 수신 측에 이 데이터가 몇 번째 데이터인지 알려주는 역할), 확인 응답 번호(수신 측이 몇 번째 데이터를 수신했는지 송신 측에 알려주는 역할)를 3way handshake에서 사용한다.
* 순서가 바뀌면 **재정렬**
* 중복 제거

#### 2. 흐름 제어 (Flow Control)
* 수신자가 감당 가능한 속도로 조절
  * Receiver 기반 제어
* TCP의 흐름 제어
  * **슬라이딩 윈도우 (Sliding Window)**: 송신자는 일정한 크기의 윈도우를 유지하면서 데이터를 전송하며, 수신자는 윈도우 크기를 조절하여 송신자에게 알린다.
  * **윈도우 크기 조절**: 수신자는 ACK 패킷을 통해 현재 수신할 수 있는 데이터 양(윈도우 크기)을 송신자에게 알린다.
* 예시) 큰 데이터를 받을 때 끊기는 경우

#### 3. 혼잡 제어 (Congestion Control)
* 네트워크 상태에 따라 속도 조절
  * Network 기반 제어
* TCP의 혼잡 제어
  * **AIMD (Additive Increase Multiplicative Decrease)**: 혼잡이 감지되지 않으면 송신자는 혼잡 윈도우 크기를 선형적으로 증가시키고, 혼잡이 감지되면 혼잡 윈도우 크기를 절반으로 줄인다.
  * **슬로우 스타트 (Slow Start)**: 새로운 연결이 설정되거나 타임아웃이 발생한 후, 송신자는 초기 혼잡 윈도우 크기를 매우 작게 설정하고, ACK를 받을 때마다 지수적으로 증가시킨다.
  * **혼잡 회피 (Congestion Avoidance)**: 혼잡 윈도우 크기가 임계값에 도달하면, 송신자는 혼잡 윈도우 크기를 선형적으로 증가시켜 혼잡을 예방한다.
  * **패킷 손실 감지**: TCP는 패킷 손실을 혼잡의 신호로 간주하며, 타임아웃이나 중복 ACK를 통해 패킷 손실을 감지한다.
* 예시) 다운로드 속도가 들쭉날쭉한 경우

#### 4. 프로세스 간 통신 (Port)
* IP - '컴퓨터'까지 전달
* 전송 계층 - '프로세스'까지 전달
  * 데이터를 받을 정확한 프로세스를 구별 (목적 어플리케이션 구별 기능)
    * TCP 헤더에 출발지&목적지 포트 번호 담아서 보내기

> [\[0722~0728\] 🤔: 전송계층이 왜 필요한데?](https://velog.io/@seahee1234/07220728-%EC%A0%84%EC%86%A1%EA%B3%84%EC%B8%B5%EC%9D%B4-%EC%99%9C-%ED%95%84%EC%9A%94%ED%95%9C%EB%8D%B0)
> [\[네트워크/Network\] 전송계층의 역할과 TCP 분석 \( + UDP\)](https://howudong.tistory.com/294)
> [네트워크 6 : 전송 계층 - Transport Layer](https://benlee73.tistory.com/166)
> [전송 계층의 개념과 필요성](https://hoji1998.tistory.com/35)

### 3) End-to-End Principle

#### 전송 계층의 핵심
> “네트워크는 단순하게, 복잡한 것은 끝단에서 해결한다”

* 신뢰성은 네트워크가 아니라 **양 끝(TCP)**이 책임짐.
* 그래서 TCP는 end-to-end 계층

## 2. 탐구 내용 (실무 / iOS 연결)

### 1) iOS에서의 전송 계층
우리는 직접 TCP를 다루지 않지만 사실 항상 사용 중

* URLSession → 내부적으로 TCP 사용
* Network.framework → TCP/UDP 직접 선택 가능

### 2) Latency의 대부분은 전송 계층에서 발생한다

#### 앱이 느린 주요 이유
* TCP Handshake (RTT 1~2번)
* Slow Start
* 재전송
* 혼잡 제어

> API가 느리다 != 서버 문제
> -> TCP 레벨에서 이미 느릴 수 있다

#### (1) 첫 요청이 느림
* 이유: TCP + TLS handshake
* 해결
  * Connection reuse (keep-alive)
  * HTTP/2 사용

#### (2) 요청이 많을 때 느려짐
* 이유: 혼잡 제어 + 큐잉
* 해결
  * 요청 batching
  * concurrency 제한

#### (3) 재시도 로직 문제
* TCP도 재전송을 하지만 앱 레벨에서도 retry 필요
  * 그러나 retry 할 경우
    * 중복 요청 위험
    * 서버 부하 증가

### 3) 신뢰성은 어디까지 TCP가 책임질까?
TCP는 전송 성공만 보장하고 비즈니스 성공은 보장하지 X

* TCP: 데이터 전달 완료 (OK)
  * **TCP 입장: 성공**
* 서버: 500 에러 발생
  - **앱 입장: 실패**

#### 정리
* TCP → **packet 단위 신뢰성**
* 앱 → **요청 단위 신뢰성 (retry, idempotency)**

#### iOS 연결
```swift
URLSession.shared.dataTask(with: request)
```
* 내부적으로 TCP는 이미 재전송하지만 retry 로직도 작성해서 활용
- 이유: **TCP와 앱의 책임 범위가 다르기 때문** 

### 4) TCP Slow Start: 왜 처음 요청이 느릴까?
TCP는 처음부터 빠르게 보내지 X

* **처음**: 아주 적은 양만 전송
* **성공 후**: 점점 증가
-> 이유: 네트워크 상태를 모르기 때문이다.


#### iOS 실무 영향
* cold start API 느림
  * 앱 처음 켰을 때 느린 이유 중 하나

#### 해결
* connection reuse
* prefetch
* warm-up request

### 5) 왜 비동기가 필수적일까

TCP는 기본적으로
* RTT 동안 대기
* 재전송 시 추가 대기

#### iOS 연결
```swift
await URLSession.shared.data(for: request)
```
- 내부적으로
  * TCP 대기
  * OS 이벤트 기반 처리
  * callback / async resume

> 즉 전송 계층의 지연을 가리기 위해 앱은 비동기 모델을 사용해야 한다.

## 3. 의문 / 논점

### 1. TCP가 재전송을 하는데 앱에서 retry를 또 하는 것은 중복이지 않나?
중복 X, 책임 레벨이 다름. 

#### TCP의 재전송
* 단위: **패킷**
* 목적: **데이터를 손실 없이 전달**
* 기준: ACK 못 받으면 재전송

#### 앱의 retry
* 단위: **요청(Request)**
* 목적: **비즈니스 성공 보장**
* 기준:
  * timeout
  * 서버 에러 (5xx)
  * 네트워크 끊김

#### 결론
> TCP - ‘보냈다’
> 앱 - ‘잘 처리됐다’

즉 retry는 중복이 아니라 다른 계층에서의 보완임.

### 2. Congestion Control은 네트워크 기준인데 앱에서 concurrency를 줄이면 왜 빨라질까?
앱이 congestion을 유발하기 때문이다.

#### TCP 관점
* congestion control은..
  * packet loss
  * RTT 증가
  * 기반으로 동작
- 이미 문제가 발생한 후 반응 (사후 대응)

#### 앱 관점
* 동시에 요청 100개 보내면
  * 서버 큐 증가
  * 네트워크 큐 증가
  * 패킷 드롭 증가
- TCP는 그때서야 감속
- 앱은 사전 제어

`앱이 과도한 요청 → 큐 증가 → RTT 증가 → TCP 감속`

#### concurrency 제한 효과
- 애초에 congestion을 덜 만듦.
- TCP가 덜 느려짐.

### 3. Slow Start가 존재하는데 짧은 요청 위주의 앱에서는 TCP가 비효율적인 구조 아닌가?
그렇기 때문에 HTTP/2, HTTP/3가 등장

#### 문제 상황: 짧은 요청 (예: API 호출)
* connection 생성
* handshake
* slow start 시작
* 끝나기 전에 요청 종료

#### 비효율 발생 이유
* TCP는 장기 연결에 최적화됨. (사전 연결도 하고..)
* 짧은 요청은 매번 초기 상태

#### 해결 전략
1) Connection reuse
   * keep-alive
   * 기존 TCP 재사용
2) HTTP/2
   * 하나의 connection으로 여러 요청
3) HTTP/3 (QUIC)
   * handshake 최소화
   * connection migration 가능

### 4. 모바일 환경에서 Wi-Fi → LTE 전환 시 기존 TCP connection은 유지될 수 있을까?
일반 TCP는 거의 유지되지 X

#### 이유
TCP는 다음에 묶여 있다.
* IP 주소
* 4-tuple (src IP, dst IP, src port, dst port)

#### Wi-Fi → LTE 전환 시
* IP 변경됨
* 네트워크 경로 변경됨

→ 기존 connection 깨짐

#### 결과
* connection reset
* 요청 실패
* retry 발생

#### 해결 기술
**1) Multipath TCP**
* 여러 네트워크 동시에 사용
* Apple이 지원 (iOS 일부)

**2) QUIC (HTTP/3)**
* connection ID 기반
* IP 바뀌어도 유지 가능