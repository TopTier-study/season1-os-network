# 스레드 수와 성능의 관계
### 학습 키워드
- CPU 코어
- Throughput

## 1. 핵심 개념
- [관련 개념 설명 문서](https://github.com/TopTier-study/season1-os-network/blob/main/CS/week02-thread-scheduling/%5B06%5D%20performance-metrics-for-systems-and-user-experience.md)

## 2. 탐구 내용 (실무 / iOS 연결)
## 스레드 수를 늘리면 성능이 항상 좋아질까?: CPU Concurrency에 따른 Throughput 실험
### 1) 실험 목적
CPU-bound 작업에서 동시 실행 작업 수(concurrency)가 증가할 때 **Throughput과 CPU 스케줄링 상태가 어떻게 변하는지 확인**한다.

- CPU 코어 수와 동시 실행 작업 수의 관계
- Throughput 증가 / 감소 지점
- 스레드 스케줄링 상태 변화

### 2) 실험 환경
| 항목    | 값                                |
|-------|----------------------------------|
| CPU   | 10 cores                         |
| OS    | macOS                            |
| 언어    | Swift                            |
| 실행 방식 | GCD (DispatchQueue.global)       |
| 측정 도구 | Xcode Instruments (System Trace) |

### 3) 실험 코드 구조
CPU-bound 연산을 수행하는 작업을 여러 개 생성하고 동시에 실행 가능한 작업 수(concurrency)를 제한하면서 수행했다.

#### CPU 작업
```swift
@inline(never)
func heavyWork(_ seed: Int, loops: Int) -> UInt64 {
    var x = UInt64(seed) &* 2862933555777941757 &+ 3037000493
    for _ in 0..<loops {
        x ^= x &<< 13
        x ^= x &>> 7
        x ^= x &<< 17
        x &+= 1
    }
    return x
}
```
- 순수 CPU 연산
- IO 없음
- 메모리 접근 거의 없음

#### 동시 실행 제어
```swift
let sem = DispatchSemaphore(value: concurrency)
```
- 세마포어로 동시에 실행되는 task 수를 제한

#### 작업 실행
```swift
DispatchQueue.global(qos: .userInitiated).async
```
- GCD global queue에서 실행

#### 실험 파라미터
| 변수                | 값                        |
|-------------------|--------------------------|
| totalTasks        | 80                       |
| loops             | 1,000,000                |
| repeats           | 3                        |
| concurrency sweep | [1, 2, 4, 5, 10, 20, 40] |

### 4) 실험 결과
#### 실행 결과
```
Active CPU cores: 10

=== concurrency=1, totalTasks=80, loops=1000000 ===
>>> START run=1 concurrency=1
<<< END   run=1 concurrency=1
run 1: 5.960s
>>> START run=2 concurrency=1
<<< END   run=2 concurrency=1
run 2: 6.004s
>>> START run=3 concurrency=1
<<< END   run=3 concurrency=1
run 3: 6.018s
best: 5.960s | throughput: 13.4 tasks/s | sink: 6

=== concurrency=2, totalTasks=80, loops=1000000 ===
>>> START run=1 concurrency=2
<<< END   run=1 concurrency=2
run 1: 3.039s
>>> START run=2 concurrency=2
<<< END   run=2 concurrency=2
run 2: 3.050s
>>> START run=3 concurrency=2
<<< END   run=3 concurrency=2
run 3: 3.019s
best: 3.019s | throughput: 26.5 tasks/s | sink: 6

=== concurrency=4, totalTasks=80, loops=1000000 ===
>>> START run=1 concurrency=4
<<< END   run=1 concurrency=4
run 1: 1.579s
>>> START run=2 concurrency=4
<<< END   run=2 concurrency=4
run 2: 1.565s
>>> START run=3 concurrency=4
<<< END   run=3 concurrency=4
run 3: 1.561s
best: 1.561s | throughput: 51.3 tasks/s | sink: 6

=== concurrency=5, totalTasks=80, loops=1000000 ===
>>> START run=1 concurrency=5
<<< END   run=1 concurrency=5
run 1: 1.414s
>>> START run=2 concurrency=5
<<< END   run=2 concurrency=5
run 2: 1.427s
>>> START run=3 concurrency=5
<<< END   run=3 concurrency=5
run 3: 1.428s
best: 1.414s | throughput: 56.6 tasks/s | sink: 6

=== concurrency=10, totalTasks=80, loops=1000000 ===
>>> START run=1 concurrency=10
<<< END   run=1 concurrency=10
run 1: 1.023s
>>> START run=2 concurrency=10
<<< END   run=2 concurrency=10
run 2: 1.000s
>>> START run=3 concurrency=10
<<< END   run=3 concurrency=10
run 3: 0.976s
best: 0.976s | throughput: 82.0 tasks/s | sink: 6

=== concurrency=20, totalTasks=80, loops=1000000 ===
>>> START run=1 concurrency=20
<<< END   run=1 concurrency=20
run 1: 1.004s
>>> START run=2 concurrency=20
<<< END   run=2 concurrency=20
run 2: 0.994s
>>> START run=3 concurrency=20
<<< END   run=3 concurrency=20
run 3: 1.005s
best: 0.994s | throughput: 80.4 tasks/s | sink: 6

=== concurrency=40, totalTasks=80, loops=1000000 ===
>>> START run=1 concurrency=40
<<< END   run=1 concurrency=40
run 1: 1.048s
>>> START run=2 concurrency=40
<<< END   run=2 concurrency=40
run 2: 1.026s
>>> START run=3 concurrency=40
<<< END   run=3 concurrency=40
run 3: 1.047s
best: 1.026s | throughput: 78.0 tasks/s | sink: 6
```

| concurrency | best time  | throughput       |
|-------------|------------|------------------|
| 1           | 5.960s     | 13.4 tasks/s     |
| 2           | 3.019s     | 26.5 tasks/s     |
| 4           | 1.561s     | 51.3 tasks/s     |
| 5           | 1.414s     | 56.6 tasks/s     |
| 10          | **0.976s** | **82.0 tasks/s** |
| 20          | 0.994s     | 80.4 tasks/s     |
| 40          | 1.026s     | 78.0 tasks/s     |

<img width="2240" height="1260" alt="스크린샷 2026-03-06 오전 8 00 35" src="https://github.com/user-attachments/assets/ebccb6a4-fb84-4e94-908c-505b37f77fe0" />

### 5) 결과 해석
#### concurrency < CPU cores
- 양상: `[1, 2, 4, 5]` 구간에서 throughput **선형 증가**
- 이유: CPU 코어가 남음.

#### concurrency ≈ CPU cores
- 양상: `[10]` 지점에서 CPU saturation 발생, **throughput 제일 높음**. (82 tasks/s)

#### concurrency > CPU cores
- 양상: `[20, 40]` 구간에서 throughput **감소**
- 원인: thread oversubscription
  - CPU 코어보다 스레드가 많아지면 스케줄러가 스레드를 번갈아서 실행한다. (time slicing) -> 추가 비용 발생
    - ’추가 비용’: 컨텍스트 스위칭, 캐시 미스, 스케줄러 오버헤드 등

#### Instruments System Trace 관찰 내용
- concurrency 증가와 동시에 CPU usage 증가

<img width="2240" height="1260" alt="스크린샷 2026-03-06 오전 7 59 14" src="https://github.com/user-attachments/assets/f91a861e-1848-4665-9604-5597d28df426" />


- 스레드 상태
  - Running: CPU에서 실제 실행 중
  - Runnable: CPU를 기다리는 스레드
  - Preempted: 스케줄러가 스레드 교체 (컨텍스트 스위칭)
  - **코어 수를 초과한 이후 runnable / Preempted 상태의 스레드 증가** -> 스케줄링 대기와 컨텍스트 스위칭 오버헤드 발생
  - -> throughput 감소

### 6) iOS 개발과의 연결
이미지 디코딩, 영상 처리 등과 같은 CPU 작업을 많은 스레드로 실행할 경우 성능이 좋아지지 않는다.
오히려 **컨텍스트 스위칭이 증가하여 latency가 증가할 수 있다.**

#### Apple이 GCD를 만든 이유
- GCD는 내부적으로 스레드 풀을 사용 -> **CPU core 수를 기반으로 스레드 수를 관리**
- 즉 **oversubscription 방지를 자동으로 수행**


### 7) iOS 환경에서 실험할 경우 변화점
macOS와 iOS는 동일한 **Darwin(XNU) 커널**을 사용하기 때문에 스케줄링의 기본 원리는 동일하다.
그러나 실제 iOS 기기에서는 다음과 같은 차이로 인해 실험 결과의 형태가 조금 달라질 수 있다.

#### 1. big.LITTLE CPU 구조
```
2 Performance cores (P-core)
4 Efficiency cores (E-core)
```
이때 activeProcessorCount는 6으로 나오지만 실제 성능은 동일하지 X
**P-core가 먼저 사용되고 이후 E-core가 사용되므로** concurrency 증가 시 macOS의 코어 수별 throughput 증가 속도와 다를 수 있다.

#### 2. QoS 기반 스케줄링
iOS에서는 **QoS(Quality of Service)**가 스케줄링에 큰 영향을 준다.
`.userInteractive`와 같은 높은 QoS는 Performance core에 우선 배치될 가능성이 높으므로 이에 따라 실험 결과가 달라질 수 있다.

#### 3. Thermal Throttling
아이폰은 발열 제한이 강하므로 CPU를 오래 100% 사용할 경우 Thermal Throttling이 발생하여 CPU 사용 빈도가 감소하게 되고 이에 따라 throughput이 감소할 수 있다.
macOS는 냉각 시스템이 더 강하기 때문에 이러한 영향이 상대적으로 적어 안정적인 실험 결과를 얻을 수 있다.
