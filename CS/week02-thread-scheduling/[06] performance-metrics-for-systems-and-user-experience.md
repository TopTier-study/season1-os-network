# 시스템과 사용자 경험의 성능 지표
### 학습 키워드
* Throughput
* Latency
* Response Time
* CPU Utilization

## 1. 핵심 개념
### Throughput
: 단위 시간 동안 시스템이 처리한 작업량
(즉 **시스템의 전체 처리 능력 지표**)

- 클수록 좋은 성능
- 여러 구간 중 **가장 낮은 구간**의 TPS를 전체 시스템의 성능으로 간주
  - 병목 구간을 파악하는 것이 중요
  - **TPS(Transaction per second)**: 초당 처리할 수 있는 Transaction의 수 (= 처리량)
    - 서비스 사용자 ↑ -> TPS 지속 증가
    - 이후 어느 시점부터 처리량 증가 X, 일정한 수준 유지 시: 해당 변곡점이 **포화지점(Saturation Point, 해당 시스템의 최대 처리량을 나타내는 지점)**
    - 포화지점 이후부터는 대기 시간(Queuing time) ↑ -> 응답 시간 증가
      - 이때의 동시 사용자 수 = 최대 허용 동시 사용자 수
    - 포화지점을 기준으로 해당 서버가 감당할 수 있는 부하의 한계를 정의함.
    > [참고 링크](https://ch4njun.tistory.com/266)
- 예시
  - 초당 처리한 HTTP 요청 수 (rps)
  - 초당 처리한 DB 쿼리 수
  - 초당 렌더링한 프레임 수

### Latency (지연 시간)
: 요청이 시스템에서 처리되기까지 발생하는 **지연 시간**
(네트워크 지연, 큐 대기 시간 등)

- 작을 수록 좋은 성능

#### 기존 서비스의 navigation latency 기준
> 참고 링크: [API 응답 속도가 얼마나 빨라야될까? \(페이지 로딩시간, API TPS, latency\)](https://gkqlgkql.tistory.com/entry/API-%EC%9D%91%EB%8B%B5-%EC%86%8D%EB%8F%84%EA%B0%80-%EC%96%BC%EB%A7%88%EB%82%98-%EB%B9%A8%EB%9D%BC%EC%95%BC%EB%90%A0%EA%B9%8C-%ED%8E%98%EC%9D%B4%EC%A7%80-%EB%A1%9C%EB%94%A9%EC%8B%9C%EA%B0%84-API-TPS-latency)
- 구글
  - 3초 이상의 페이지 로딩 시간이 걸릴 경우 53%의 모바일 사용자가 이탈한다.
  - 0.5초의 추가 페이지 로딩 시간이 20%의 트래픽 손실을 발생시킨다.
  - 따라서 페이지 로딩 시간을 최대 2초, 목표치를 0.5초로 설정하였다.
- 아마존
  - 페이지 로딩 시간이 100ms 증가할 때마다 1%의 매출이 감소한다.
- 월마트
  - 페이지 로딩 시간이 1초 개선될 때마다 전환율이 2% 증가한다.


### Response Time (응답 시간)
: 요청 이후 **사용자가 응답을 받기까지의 시간**

`Response Time = Queue time + Processing time + Network latency`

- 예시
  - 상황
    1. 버튼 클릭
    2. 버튼 색상 변경 (즉시)
    3. 네트워크 요청
    4. 응답으로 받은 데이터 화면에 표시
  - 개념 적용
    - Response Time = 버튼 반응 시간
    - Latency = 네트워크 요청 완료 시간

### CPU Utilization
: CPU가 실제 작업을 수행한 시간의 비율

- `CPU busy time / total time`
  - **CPU 사용률이 높음 != 성능이 좋은 시스템**
    - CPU 100% 시의 상황
      1. 요청 증가
      2. 실행 큐 길이 증가
      3. CPU를 기다리는 작업 증가
      4. 대기 시간 증가
      5. Latency 증가
    - 실행 큐에 많은 스레드 존재 시 컨텍스트 스위칭 비용 증가 -> 전체 시스템 성능 저하


## 2. 탐구 내용 (실무 / iOS 연결)
## 2-1) 각 성능 지표 별 관계
### Throughput과 Latency의 관계
> 참고 링크: [Throughput과 Latency](https://velog.io/@arnold_99/Throughput%EA%B3%BC-Latency)

예시: A, B, C 지역을 잇는 고속도로에서
<img width="3886" height="967" alt="고속도로 예시" src="https://github.com/user-attachments/assets/761ad022-8fc0-479e-9f3c-f8667a981106" />

- A-C 지역 간 Latency: 각 구간의 소요 시간 합계인 5시간
* A-C 지역 간 Throughput: 각 구간에 도달하는 차량 대수 중 최소값인 800대/시간

- 여기서 B-C 지역 사이의 고속도로에서 정체 발생 시 해당 지점이 병목 지점
  - 도로 확장 공사를 통한 정체 해소 시 **Throughput ↑** (더 많은 차가 지나다닐 수 있으므로) & **Latency ↓** (해당 구간 고속도로에서의 정체가 사라지므로 A지역에서 C지역으로 도달하는 데에 걸리는 시간이 줄어듬)

#### 그러나 Queue가 들어가는 경우
- 작업 처리 과정
  1. request
  2. queue
  3. work
  4. response
- 여기서 **Latency = 큐 대기 시간 + 작업 처리 시간**

#### Little’s Law
`L = λW`
- L = 시스템 안의 평균 작업 수
- λ = 처리율 (Throughput)
- W = 평균 Latency

즉 `시스템 내 요청 수 = Throughput x Latency`
- 예시
  - Throughput: 100 req/s
  - Latency: 0.5s
  - = ‘평균적으로 50개의 요청이 시스템 내에 존재한다’
- 요청이 더 몰릴 시 큐 대기 시간이 증가하므로 **Latency 증가**, Throughput은 그대로
  - Throughput(처리 능력)은 worker 수, CPU 등과 같은 리소스 한계에 영향을 받기 때문에 요청이 기본적인 동시 처리 가능량을 넘으면 큐에 요청이 쌓임. -> 즉 처리 능력은 그대로 유지됨.

#### CPU 스케줄링에서의 적용
1. **FCFS** (First Come First Serve): 먼저 도착한 작업부터 처리
   - CPU는 거의 쉬지 않기 때문에 Throughput은 좋음.
   - 그러나 늦게 도착한 짧은 작업의 Latency는 나쁨. (짧은 작업을 위해 오래 기다려야 하므로)
2. **SJF** (Shortest Job First): 짧은 작업 먼저 처리
   - 평균 Latency 감소 (짧은 작업부터 빠르게 해치우므로)
   - 그러나 긴 작업 기아현상 발생 우려
3. **Round Robin**: CPU를 타임슬라이스에 맞춰서 분배
   - response time 좋음.
   - 그러나 컨텍스트 스위칭 비용이 증가하고, Throughput 감소

결국 스케줄링을 통해 Throughput, Latency 사이의 균형을 맞춰야 한다.
따라서 대부분 OS는 둘 사이의 **균형을 맞추기 위한 스케줄러**를 사용한다. (Linux - CFS, iOS - Mach scheduler)

### Latency vs Response Time
#### Latency
요청이 **클라이언트 -> 서버 -> 클라이언트**로 왕복 이동하는 데 걸리는 시간
(데이터가 이동하는 데 걸리는 시간)
물리적 거리, 네트워크 상태, 라우팅, 패킷 전송 시간 등 **전송 지연의 영향**을 받는다.

#### Response Time
요청을 보낸 순간부터 최종 응답을 받을 때까지 걸리는 전체 시간
(**Response Time = Latency + 서버 처리 시간**)
즉 `Response time ≥ Latency`가 항상 성립한다.

#### 두 개를 구분하는 이유
- Latency가 높은 경우
  - 네트워크, 거리, 라우팅 등의 문제
- Response Time이 높은 경우
  - 서버 처리, DB, 큐, 알고리즘 등의 문제

사용자가 체감하는 것은 Response Time이지만, 이를 분석하기 위해 시스템 엔지니어는 latency, processing time, queue time을 나눠서 확인한다.

> 참고 링크: [Understanding Latency vs Response Time](https://docs.openstatus.dev/concept/latency-vs-response-time/)

---
## 2-2) 모바일 앱 성능 관점: 기준 및 전략
### iOS에서의 성능 기준
모바일 앱에서는 **사용자 경험 중심의 성능 기준**이 중요

1. UI 프레임 기준
   - iOS UI는 디스플레이 주기에 맞춰 업데이트 (`60Hz 디스플레이 → 1프레임 = 16.67ms`)
   - 즉 `UI 계산 + layout + rendering` 작업이 16ms 이내에 완료되어야 한다.
   - 초과 시 Frame Drop 발생
   - 최근 iPhone Pro 모델은 120Hz를 지원하기 때문에 더 빠른 렌더링이 필요 (`120Hz → 1프레임 = 8.33ms`)
2. 사용자 반응 시간 기준
   - 사용자가 체감하는 반응 시간 기준
     ```
     100ms 이하 → 즉각적인 반응
     100~1000ms → 지연이 느껴짐
     1초 이상 → 사용자가 작업 흐름을 잃음
     ```
   - 따라서 iOS 앱에서는 터치 시의 UI 반응을 100ms 이하로 유지하는 것이 권장된다.

### iOS에서의 Latency, Throughput 문제
#### iOS에서의 Latency
iOS에서 latency 문제의 가장 흔한 원인은 **Main Thread Blocking**이다.

메인 스레드가 다음과 같은 작업으로 오래 점유되는 경우
- 네트워크 처리
- 이미지 디코딩
- JSON 파싱
- layout 계산

-> UI 이벤트 처리와 렌더링이 지연되면서 사용자가 체감하는 latency 증가

#### iOS에서의 Throughput
iOS에서는 Throughput 문제가 렌더링 파이프라인에서 자주 발생한다.

- 예시
  - 스크롤 과정
    1. 셀 생성
    2. layout 계산
    3. 이미지 디코딩
    4. view rendering
- 스크롤 작업 과부하 시 프레임 렌더링 throughput 감소
- -> 스크롤이 버벅거리고 프레임 드랍 발생

#### 해결 전략
- background thread로 무거운 작업 분리
- 셀 재사용
- 렌더링 비용 최소화

-> 메인 스레드 latency 감소, 프레임 throughput 증가

> 참고 링크: [Latency in iOS Apps: 6 Proven Swift Strategies to Optimize Speed](https://gauravtakjaipur.medium.com/latency-in-ios-apps-6-proven-swift-strategies-to-optimize-speed-d3d7aa1c0292)
> (미디움 글 이슈로 끝까지 못 읽었는데 내용이 좋은 것 같음)

---
### 참고: Threads iOS 앱 성능 전략
> 참고 링크: [How we think about Threads’ iOS performance](https://engineering.fb.com/2024/12/18/ios/how-we-think-about-threads-ios-performance/)
Threads iOS 팀은 성능을 단순히 코드 최적화가 아닌 **사용자가 실제로 경험하는 성능**이라 정의하고 측정한다.

 #### a. 실제 사용하는 주요 지표
1. **%FIRE (Frustrating Image Render Experience)**: 이미지 렌더링 과정에서 사용자가 불편을 겪는 비율
   - **화면에 이미지가 떠야할 때 1초 이상 걸리거나 사용자가 기다리지 못하고 떠난 경우**를 느린 로드로 간주
   - 느린 로드의 비율이 전체 이미지 중 **15% 이상**인 경우 심각한 문제로 판단
2. **TTNC (Time-to-Network Content)**: 앱 실행 후 실제 콘텐츠가 화면에 나타날 때까지 걸리는 시간
3. **cPSR (Creation-Publish Success Rate)**: 콘텐츠 작성 후 게시가 성공적으로 완료되는 비율
   - **사진, 동영상 콘텐츠**는 업로드 시간이 길고 데이터 사용량이 많기 때문에 실패 가능성 ↑, 앱 백그라운드 전환 시 업로드 중단 가능
   - 해결 전략
     - **초안 저장**: 업로드가 실패한 경우에도 게시물을 잃지 않도록 저장.
       - 도입 후 게시 관련 사용자 불만 보고 26% 감소
     - **Optimistic 텍스트 게시**: 백엔드가 게시 요청을 받는 즉시 게시되었다는 토스트 알림 띄움. 이후 처리 실패 시 콜백 (요청이 일단 수신되면 성공 가능성이 매우 높기 때문)

#### b. Threads 팀 실험: navigation latency 인위적 증가 실험
- 실험 내용
  - 프로필, 활동 피드 등 특정 화면으로 이동 시 **의도적으로 latency를 추가**하여 사용자의 반응을 보는 경계 테스트 수행
- 결과
  - latency가 증가할수록 앱과의 상호작용 감소
    - 사용자가 읽는 글 수 감소
    - 게시 활동 감소
    - 앱 사용 시간 감소
  - -> 즉 **사용자는 latency에 매우 민감하다**는 사실을 확인함.

#### c. 성능 관리 전략
1. **Observability 중심의 성능 관리: 내부 로깅 시스템 SLATE**
   - UI에서 발생하는 이벤트에 마커를 삽입하여 성능 측정
     - 개발자가 마커를 따로 설정하지 않아도 공통 컴포넌트를 사용하면 자동으로 데이터를 수집하여 성능 분석
   - 각 이벤트 발생 시의 내부 스레드 타임라인을 분석하여 어떤 스레드에서 병목이 발생하는지 확인
2. **Binary Size 관리**
   - 코드 추가 시 바이너리 사이즈 증가율이 임계치를 넘으면 머지 차단
   - 이 방식으로 앱 실행 속도 & 메모리 사용량 관리
   - 2024 기준 인스타그램 대비 1/4 수준의 앱 크기 유지

#### d. iOS 주요 성능 문제
1. **Navigation Latency**: 화면 전환이 느리면 사용자는 앱이 느리다고 느낌.
2. **이미지 렌더링**: 소셜 앱에서는 이미지가 많기 때문에 이미지 디코딩/렌더링 성능이 중요함. (`%FIRE` 지표 사용 배경)
3. **앱 실행 속도**: 앱 실행 후 피드가 나타나는 시간이 길면 사용자는 앱을 닫음. (`TTNC` 지표 사용 배경)

---

## 3. 의문 / 논점
### 3-1) 사용자가 느끼는 성능과 실제 성능이 항상 일치할까?
그렇지 않다.

- **예시 UX 패턴**
  - optimistic UI
  - skeleton screen
-> 실제 latency는 동일하지만 사용자 경험을 개선할 수 있는 전략이 존재한다.

실제 성능 개선도 중요하지만 한정된 리소스 내에서는 한계가 있다.
따라서 이와 동시에 사용자 경험 개선을 위한 추가 전략을 항상 고려해야 한다.

### 3-2) 왜 iOS의 UI 업데이트는 Main Thread에서만 동작해야 할까?: UIKit과 SwiftUI의 Thread-Unsafe

> “UIKit classes should be used only from an application’s main thread.”
> [Apple UIKit 공식 문서](https://developer.apple.com/documentation/uikit/)

UI 관련 클래스를 메인 스레드에서만 사용해야 하는 이유는 단순 규칙을 넘어 **프레임워크의 설계 자체가 이와 같이 되어 있기 때문**이다.

#### UIKit과 SwiftUI의 Thread-Unsafe
1. UI 프레임워크를 Thread-Safe하게 만들면 성능이 크게 떨어진다.
   - UIKit은 매우 큰 프레임워크 (뷰, 레이아웃 등 수많은 상태를 가짐)
   - 이를 여러 스레드에서 안전하게 접근하도록 만들기 위해서는 **lock, mutex 등과 같은 매커니즘 필요**
   - 그러나 이러한 동기화는 다음과 같은 문제를 발생시킴.
     - lock 경쟁
     - 컨텍스트 스위칭 증가
     - 성능 저하
   - 따라서 오히려 느려질 수 있다.
2. 대신 **UI가 단일 스레드 모델을 사용하도록 설계**하였다.
   - UI를 메인 스레드에서만 접근할 수 있도록 하면 data race 우려가 없고, lock과 동기화 비용이 필요없음.
     - Thread-Safe의 문제를 **구조적으로 제거**함.
   - 또한 iOS의 UI 렌더링은 `Core Animation → Render Server → GPU` 파이프라인으로 이어짐. (해당 파이프라인은 **메인 RunLoop**에 맞춰 동작)
     - 따라서 UI 상태를 단일 스레드에서 관리하는 것이 **프레임 일관성을 유지**하기에 가장 효율적인 구조이다.

> 참고 링크 1) [Thread-Safe Class Design · objc.io](https://www.objc.io/issues/2-concurrency/thread-safe-class-design/)
> 참고 링크 2) [iOS: Why the UI need to be updated on Main Thread](https://medium.com/@duwei199714/ios-why-the-ui-need-to-be-updated-on-main-thread-fd0fef070e7f)
> 참고 링크 3) [About Threaded Programming](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/AboutThreads/AboutThreads.html#//apple_ref/doc/uid/10000057i-CH6-SW2)
