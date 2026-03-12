# Semaphore와 다른 방식 비교 / iOS에서의 Semaphore

### 학습 키워드

`# semaphore` `# mutex` `# monitor`

## 1. 핵심 개념

### Semaphore

#### [1] 등장 배경 - Mutex의 한계

> **Mutex**  
> lock을 획득한 스레드 혹은 프로세스만 임계 구역에 접근 가능.  
> `lock 획득(acquire) → 임계 구역 실행 → lock 해제(release)`

Mutex는 Critical Section을 보호하는 가장 기본적인 방법이지만, 한계가 존재합니다.

- **Busy Waiting**: lock을 얻지 못한 스레드가 계속 루프를 돌며 CPU를 낭비합니다.
- **1:1 제어만 가능**: 한 번에 하나의 스레드만 접근 허용. N개의 리소스(예: DB 커넥션 풀)를 N개의 스레드가 동시에 쓰게 하는 것이 어렵습니다.
- **순서 동기화 불가**: 'A 작업이 끝난 후 B 실행' 같은 실행 순서 제어에는 적합하지 않습니다.

이런 한계를 보완하기 위해 Dijkstra가 Semaphore를 제안했습니다.

#### [2] 개념 설명

Semaphore는 정수 값 S와 `wait()` / `signal()` 두 가지 원자적 연산으로 구성됩니다.

```swift
func wait(_ S: inout Int) {
	while S <= 0 {
		// busy wait
	}
	S -= 1
}

func signal(_ S: inout Int) {
	S += 1
}
```

`sleep()`으로 대기 큐에 넣고, `signal()` 시 `wakeup()`으로 깨우는 방식을 통해 busy waiting 문제를 해소합니다.

**binary vs counting**

- **Binary Semaphore**: S가 0과 1만 가짐. Mutex Lock과 유사하게 동작.
- **Counting Semaphore**: S가 N으로 초기화. 리소스를 N개의 스레드가 동시에 사용 가능. S가 0이 되면 이후 스레드는 대기.

**순서 동기화 예시 (A 완료 후 B 실행 보장)**  
프로세스 A의 `작업 a`, 프로세스 B의 `작업 b`가 있고, b는 a 완료 후에만 실행 가능한 경우:

```swift
// 프로세스 A
a()
signal(&flag)

// 프로세스 B
wait(&flag)
b()
```

`signal`이 `flag`를 사용 가능 상태로 만들기 때문에 `a` → `b` 순서가 보장됨.

---

### Monitor

#### [1] 등장 배경

세마포어를 직접 사용할 때 아래 실수가 발생하면 문제가 생깁니다.

1. signal과 wait의 순서가 뒤바뀌거나 -> 동시 접근 발생
2. signal 대신 wait이 쓰이거나 (= wait 두 번) -> 무한 블로킹 발생
3. signal이나 wait 중 하나, 혹은 둘 다 생략될 때 -> 동시 접근 발생하거나 무한 블로킹

#### [2] 개념 설명

> **추상 데이터 타입(ADT, Abstract Data Type)**: 데이터와 그 데이터의 연산 메서드를 캡슐화한 것.  
> **모니터 타입(monitor type)**: 상호 배제와 함께 제공되는 연산을 포함하는 ADT.

모니터 내부에서 프로세스 동기화를 제공하기 위해 **조건 변수(condition variable)** 구조체가 사용됩니다. (`condition x, y;` 형태로 선언)  
조건 변수에는 `wait`과 `signal` 연산만 제공됩니다.  
예를 들어 `x.wait()`을 호출한 프로세스는 다른 프로세스가 `x.signal()`을 호출할 때까지 일시 중지됩니다.`x.signal()`은 일시 중지된 프로세스 하나만 재개하며, 대기 중인 프로세스가 없으면 **아무 일도 하지 않습니다** (세마포어의 signal과의 차이점).

**모니터 내 프로세스 재개 순서 결정**  
대기 중인 프로세스들 중 어느 것을 선택할지는 **조건부 대기 구조(conditional-wait construct)** 로 결정됩니다.`wait()` 호출 시 우선순위 번호(priority number)를 함께 전달하고, `signal()` 호출 시 우선순위 번호가 가장 작은 프로세스를 선택합니다.

---

### Semaphore와 다른 방법 비교

#### Semaphore vs Mutex locks vs Monitor

| -                    | Semaphore                                                        | Mutex locks                                      | Monitor                                                                 |
| -------------------- | ---------------------------------------------------------------- | ------------------------------------------------ | ----------------------------------------------------------------------- |
| **동작 원리**        | 정수 카운터(S)로 접근 제어. `wait()`으로 감소, `signal()`로 증가 | lock/unlock으로 단순 상호 배제. 소유권 개념 존재 | condition 변수 + 상호 배제를 언어/라이브러리 수준에서 제공              |
| **사용 목적**        | 유한 리소스 N개 동시 접근 제어, 순서 동기화                      | Critical section 보호 (1개 스레드만)             | 복잡한 동기화 조건 추상화를 통해 관리. 잘못된 `wait`/`signal` 사용 방지 |
| **signal 기억 여부** | 기억됨. 대기자 없어도 S++ 유지                                   | 해당 없음                                        | 기억 안 됨. 대기자 없으면 소멸                                          |
| **iOS 키워드**       | `DispatchSemaphore`                                              | `NSLock`, `os_unfair_lock`, `pthread_mutex`      | `NSCondition`, `NSConditionLock`                                        |

> [!TIP] **signal의 '기억' 여부**  
> Semaphore의 `signal()`은 S++로 **기억됩니다**. 대기자가 없어도 카운트가 올라가므로, 나중에 오는 스레드가 바로 통과합니다.  
> 반면 Monitor의 `condition.signal()`은 **기억되지 않습니다**. 대기자가 없으면 그냥 소멸되며, 이후 `wait()`을 호출하는 스레드는 그대로 대기합니다.
>
> ```swift
> // Semaphore — signal이 기억됨
> let semaphore = DispatchSemaphore(value: 0)
> semaphore.signal() // 아무도 기다리지 않아도 내부 카운트가 1이 됨
> // ... 나중에 ...
> semaphore.wait() // 카운트가 1이므로 바로 통과
>
> // Monitor(NSCondition) — signal이 기억 안 됨
> let condition = NSCondition()
> condition.signal() // 기다리는 스레드 없으면 소멸
> // ... 나중에 ...
> condition.wait() // 앞서 signal이 있었어도 그냥 대기
> ```

## 2. 탐구 내용 (실무 / iOS 연결)

### iOS에서의 Semaphore<!-- {"fold":true} -->

iOS에서는 `DispatchSemaphore`를 통해 Semaphore를 사용합니다.

#### Counting Semaphore — 동시 네트워크 요청 수 제한

> `dataTask`의 클로저 전체가 리소스를 사용하는 구간  
> 네트워크 연결이 리소스고, 요청이 완료되면(`signal()`) 슬롯을 반환하는 구조

```swift
// 동시 요청을 최대 3개로 제한 (DB 커넥션 풀과 동일한 개념)
let semaphore = DispatchSemaphore(value: 3)

for url in urls {
    semaphore.wait()                        // 슬롯 획득
    URLSession.shared.dataTask(with: url) { _, _, _ in
        // 여기가 리소스(네트워크 연결) 사용 구간
        // dataTask 자체가 네트워크 연결을 점유하고 있는 것
        semaphore.signal()                  // 슬롯 반환
    }.resume()
}
```

#### Binary Semaphore — 비동기 작업을 동기처럼 기다리기

```swift
// 테스트 코드에서 비동기 작업 완료 대기
let semaphore = DispatchSemaphore(value: 0)
var result: Data? // 리소스
URLSession.shared.dataTask(with: url) { data, _, _ in
	result = data
	semaphore.signal()
}.resume()

semaphore.wait() // 완료될 때까지 현재 스레드 블락
// result 사용 가능
```

> [!WARNING] 메인 스레드에서 `wait()`하면 UI가 멈추므로 반드시 백그라운드에서만 사용해야 합니다. Swift Concurrency 환경에서는 `withCheckedContinuation`이 더 적합합니다.

### iOS에서의 Monitor<!-- {"fold":true} -->

Monitor의 핵심은 '상호 배제 + 조건 변수를 하나로 묶는 것'입니다. iOS에서는 `NSCondition`이 이에 해당합니다.

#### NSCondition — Producer/Consumer 패턴

```swift
let condition = NSCondition()
var buffer: [Int] = []
let maxSize = 5

// Producer
func produce(_ item: Int) {
	condition.lock() // Monitor 진입
	while buffer.count == maxSize {
		condition.wait() // 버퍼가 찰 때까지 대기 + lock 해제
	}
	buffer.append(item)
	condition.signal() // Consumer에게 알림
	condition.unlock() // Monitor 퇴장
}

// Consumer
func consume() -> Int {
	condition.lock()
	while buffer.isEmpty {
		condition.wait() // 버퍼가 빌 때까지 대기 + lock 해제
	}
	let item = buffer.removeFirst()
	condition.signal() // Producer에게 알림
	condition.unlock()
	return item
}
```

> [!NOTE] `condition.wait()`은 호출 즉시 내부적으로 lock을 해제하므로, 다른 스레드가 Monitor에 진입할 수 있습니다. 깨어나면 자동으로 lock을 다시 획득합니다.

#### Swift Actor — 현대적인 Monitor

Swift 5.5부터 도입된 Actor는 Monitor 개념을 언어 수준에서 구현한 것입니다.  
상호 배제를 컴파일러가 보장해주므로 lock/unlock을 직접 다루지 않아도 됩니다.

```swift
actor BankAccount {
	private var balance: Double = 0

	func deposit(_ amount: Double) {
		balance += amount // 자동으로 상호 배제 보장
	}

	func withdraw(_ amount: Double) -> Bool {
		guard balance >= amount else { return false }
		balance -= amount return true
	}
}

// 외부에서 접근 시 await 필요 (자동으로 직렬화됨)
let account = BankAccount()
await account.deposit(100)
```

### DispatchSemaphore와 Swift Concurrency의 충돌

> 실험 프로젝트 -> references/semaphore-experiment/semaphore/

근본적인 원인은 **DispatchSemaphore는 스레드를 블로킹**하고, **Swift Concurrency는 스레드를 블로킹하지 않는다는 전제 위에 설계**됐다는 점입니다.

**Swift Concurrency**로 스레드 개수가 제한된 환경에서 세마포어로 스레드를 점유해버리면, 그 스레드는 시그널을 받을 때까지 아무 일도 못 하면서 자리만 차지합니다.

**GCD**의 concurrent queue는 스레드가 부족하면 **새로운 스레드를 생성**합니다. 그래서 세마포어로 블로킹해도 시스템이 스레드를 더 만들어서 다른 작업을 처리할 수 있었습니다. 물론 이것도 스레드 폭발의 위험이 있지만, 최소한 데드락은 피할 수 있었습니다.

#### 문제 상황

문제는 이런 코드가 여러 Task에서 동시에 실행될 때 생깁니다. 6코어 기기에서 6개의 Task가 모두 `wait()`에 걸리면, pool의 모든 스레드가 소진됩니다. `URLSession`의 completion handler도 결국 이 pool에 스케줄링될 수 있는데, 남은 스레드가 없으니 `signal()`이 영원히 호출되지 못합니다. 결과적으로 모든 것이 멈추는 완전한 데드락입니다.

```swift
/// 세마포어로 비동기 작업을 동기화하는 (잘못된) 함수
func fetchDataWithSemaphore(id: Int) async {
    let semaphore = DispatchSemaphore(value: 0)

    // 비동기 작업을 시뮬레이션 (0.5초 딜레이)
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
        // ...
        semaphore.signal()
    }

    // ❌ 핵심 문제: cooperative thread pool의 스레드를 블로킹!
    // Swift Concurrency의 스레드 풀은 코어 수만큼만 스레드를 가짐.
    // 모든 스레드가 여기서 wait()에 걸리면,
    // signal()을 호출할 DispatchQueue.global()의 블록도
    // 실행될 스레드를 얻지 못할 수 있음 → 데드락
    semaphore.wait()
}
```

#### 대안

콜백 기반 API를 async 환경에서 사용할 때는 **withCheckedContinuation**을 써야 합니다.

이 방식은 스레드를 블로킹하지 않습니다. await 지점에서 현재 스레드를 **양보(yield)** 하고, continuation이 resume될 때 다시 스레드를 할당받습니다. 그 사이에 스레드는 다른 Task를 처리할 수 있습니다.

```swift
/// continuation을 사용하여 스레드를 블로킹하지 않는 (올바른) 함수
func fetchDataWithContinuation(id: Int) async -> String {
    let result: String = await withCheckedContinuation { continuation in
        // 비동기 작업을 시뮬레이션 (0.5초 딜레이)
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            let data = "Data"
            // ✅ 스레드를 블로킹하지 않고 결과를 전달
            // await 지점에서 스레드는 양보(yield)되어 다른 Task가 사용 가능
            continuation.resume(returning: data)
        }
    }
    // ✅ resume이 호출되면 여기서부터 다시 실행됨
    //    이때 런타임이 사용 가능한 스레드를 할당해줌

    return result
}
```

**핵심 원칙: async 컨텍스트에서는 절대 스레드를 블로킹하지말아야 한다.**

## 3. 의문 / 논점

### Spinlock과 Mutex locks의 차이가 뭐지?

> [스핀락\(Spinlock\) vs 뮤텍스\(Mutex\) vs 세마포어\(Semaphore\)](https://yscho03.tistory.com/292)

둘 다 상호 배제를 위한 lock이지만, lock을 얻지 못했을 때의 동작이 다릅니다.

- **Spinlock**: 대기 시간이 매우 짧을 때 유리. 컨텍스트 스위칭 비용 없음. 하지만 대기가 길어지면 CPU 낭비.
- **Mutex**: 대기 시간이 길거나 불확실할 때 유리. 스레드를 재우므로 CPU 효율적. 하지만 컨텍스트 스위칭 비용 발생.

iOS에서는 `os_unfair_lock`이 Spinlock과 Mutex의 중간 형태입니다.  
짧은 대기는 spin하고, 길어지면 sleep으로 전환합니다.  
예전에 쓰이던 `OSSpinLock`은 Priority Inversion 문제로 deprecated 되었습니다.

```swift
// Spinlock: 계속 루프 돌며 대기 (Busy Waiting)
while !tryLock() { // CPU를 계속 사용하며 spin }

// Mutex: 스레드를 sleep 시키고 대기 큐에 넣음
if !tryLock() { sleep() // 컨텍스트 스위칭 발생 }
```

> [!NOTE] **Mutex가 Busy waiting 문제를 가지고 있다고 책에서 본 것 같은데?**  
> -> Spinlock은 의도적으로, 항상 busy waiting을 선택한 것이고,  
> 현대 OS의 Mutex는 busy waiting을 **sleep으로 대체**함.

### Binary semaphore와 Mutex locks의 차이는 뭐지?

> [Difference between binary semaphore and mutex](https://stackoverflow.com/questions/62814/difference-between-binary-semaphore-and-mutex)

겉으로는 둘 다 '0 아니면 1'로 동작해서 동일해 보이지만, 핵심 차이는 소유권입니다.

- **Mutex Lock**: lock을 획득한 스레드만 unlock 가능
- **Binary Semaphore**: 소유권 없음. A 스레드가 `wait()`하고 B 스레드가 `signal()` 가능

```swift
// Binary Semaphore — 소유권 없음 (순서 동기화에 활용)

// Thread A 					Thread B
// 작업 수행 ...
semaphore.signal() 				// semaphore.wait() 대기 중이었다면 깨어남
```

따라서 순서 동기화(A 후 B)에는 Binary Semaphore가 적합하고, Critical Section 보호에는 Mutex가 더 안전합니다.

## 4. 참고 자료

[Operating System Concepts](https://product.kyobobook.co.kr/detail/S000003114660)  
[모니터 vs 세마포어](https://miind.tistory.com/324)
