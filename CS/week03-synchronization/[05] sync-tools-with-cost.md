# iOS의 여러 가지 동기화 도구 비교하기

### 학습 키워드

- 동기화 비용 (락 경합, 병목)
- NSLock, GCD, os_unfair_lock, actor
- NSRecursiveLock, NSCondition, NSConditionLock, Atomic

## 1. 핵심 개념

### 동기화 비용

- 멀티스레드나 멀티프로세스 환경에서 공유 자원에 대한 동시 접근을 제어하기 위해 락, 세마포어 등의 동기화 도구를 사용할 때 발생하는 성능 저하와 자원 소모

### 동기화 비용의 요인

1. 컨텍스트 스위칭 오버헤드
    - 아래와 같이 락을 통해 두 프로세스를 동기화하는 과정에서, 컨텍스트 스위칭은 최소 2번 발생한다.
    - 이때 많은 CPU 사이클이 소모되고, 캐시가 다른 스레드의 데이터로 덮어써지면서 캐시 미스도 발생할 수 있어 오버헤드가 된다.
    
    ```c
    스레드 B가 락 획득 시도
        ↓
    이미 스레드 A가 락 보유 중
        ↓
    스레드 B는 대기 상태로 전환 (sleep)
        ↓
    OS가 다른 스레드로 컨텍스트 스위칭
        ↓
    스레드 A가 락 해제
        ↓
    OS가 스레드 B를 다시 깨움 (wake)
        ↓
    스레드 B로 컨텍스트 스위칭
    ```
    
2. 커널 모드 전환 비용
    - 유저 모드에서 ‘락’을 요청할 경우 커널 모드로의 전환이 필요하므로 이에 대한 비용이 오버헤드로 작용한다.
3. 캐시 일관성 유지 비용
    - 현대 시스템에서 코어는 각자의 캐시를 가진다.
    - 한 코어에서 공유 변수를 수정하면, 다른 코어의 캐시에 있는 값은 '무효’가 된다.
    동기화 도구는 모든 코어가 최신 값을 보도록 강제하는 **메모리 배리어(Memory Barrier)** 명령을 실행하고, 이때 메인 메모리와의 동기화에 걸리는 시간이 오버헤드로 작용한다.
4. 락 경합으로 인한 병목 현상
    - 동기화 비용은 대기하는 프로세스나 스레드의 수가 많을 수록 기하급수적으로 증가한다.
    - 이때 **여러 스레드가 동시에 하나의 락을 얻기 위해 경쟁하는 상태를 락 경합**이라고 한다.
    락 경합 상태에서 발생하는 성능적 문제는 아래와 같다.
        - 직렬화
            - 병렬로 처리될 수 있는 멀티코어 환경임에도 불구하고, 락 때문에 작업이 한 줄로 서서 수행되어 CPU 활용률이 급감한다.
        - 우선순위 역전
            - 중요한 작업이 낮은 우선순위 작업이 쥐고 있는 락을 기다리느라 멈춰버리는 현상이 발생한다.

## 2. 탐구 내용 (실무 / iOS 연결)

### iOS에서 사용되는 동기화 방법

### **1. NSLock**

- **동일한 애플리케이션 내에서 여러 스레드의 실행 동작을 조정하는 클래스**
- **사용 방식**
    
    ```swift
    let lock = NSLock()
    
    func criticalSection() {
        lock.lock()
        // 공유 자원 접근 및 수정
        lock.unlock()
    }
    ```
    
- **특징 및 주의점**
    - POSIX thread(pthread)를 기반으로 구현된 뮤텍스에 해당한다.
    - **Objective-C 기반의 클래스 인스턴스이므로 생성 및 호출 시 약간의 오버헤드가 발생한다.**
    - **동일한 스레드에서 `lock()`을 두 번 호출하면 자기 자신을 기다리는 데드락에 빠질 수 있다.**
    - **timeout 기능**
        - 데드락 위험을 줄이기 위해 특정 시점까지만 락 획득을 시도하고, 실패 시 스레드 점유를 해제한다.
        - 사용 방식
        
        ```swift
        let lock = NSLock()
        let timeoutDate = Date(timeIntervalSinceNow: 2.0) // 2초 뒤 시점
        
        func performTaskWithTimeout() {
            // 2초 동안만 락 획득을 시도함
            if lock.lock(before: timeoutDate) {
                defer { lock.unlock() }
                // 락 획득 성공: 임계 구역 작업 수행
                print("락 획득 성공")
            } else {
                // 2초가 지나도 락을 못 얻은 경우
                print("타임아웃: 작업을 포기하거나 다른 처리를 수행")
            }
        }
        ```
        

### 2. DispatchQueue (Serial 큐)

- **GCD의 직렬 큐를 이용해 작업들의 순서를 제어한다. (sync/async)**
- **사용 방식**
    
    ```swift
    let serialQueue = DispatchQueue(label: "com.sync.queue")
    
    // 1. 동기 방식: 작업 완료를 기다림 (데이터 정합성 확보)
    func syncTask() {
        serialQueue.sync {
            // 공유 자원 보호 및 순차 실행
        }
    }
    
    // 2. 비동기 방식: 작업을 던져두고 즉시 복귀 (응답성 확보)
    func asyncTask() {
        serialQueue.async {
            // 백그라운드(글로벌 큐)에서 순차적으로 실행
        }
    }
    ```
    
- **특징 및 주의점:**
    - **추상화:** 락을 직접 다루지 않고 큐의 순서에 작업을 맡겨 데이터 레이스를 방지할 수 있다.
    - **실행 순서의 명확화 (중요):** `async`로 실행해도 **해당 Serial 큐 내부에서의 실행 순서는 보장된다.** 다만, 호출한 쪽(Caller)에서 작업이 언제 끝나는지 알 수 없을 뿐이다.
    - **병목 현상:** sync를 사용할 경우 모든 작업이 한 줄로 서서 실행되므로, 처리하는 작업이 길어지면 멀티코어의 성능을 제대로 활용하지 못하고, async의 경우 작업이 과도하게 많으면, 처리되지 못한 작업들이 큐에 쌓이면서 전체 성능이 저하될 수 있다.
    - 메인 큐에서 `sync`를 호출하거나 동일한 Serial 큐 내부에서 다시 그 큐에 sync를 보내면 스레드가 멈추는 데드락이 발생할 수 있다.

### 3. Dispatch Barrier

- **Concurrent Queue에서 실행 중인 작업들의 읽기 / 쓰기 작업을 분리해 동기화하는 도구**
- **사용 방식**
    
    ```swift
    let concurrentQueue = DispatchQueue(label: "com.barrier.queue", attributes: .concurrent)
    
    // 읽기: 여러 스레드 동시 허용
    concurrentQueue.sync { print(data) }
    
    // 쓰기: Barrier를 사용하여 독점 실행 (Serial하게 동작)
    concurrentQueue.async(flags: .barrier) {
        // 쓰기 작업 수행
    }
    ```
    

<img width="700" height="397" alt="image" src="https://github.com/user-attachments/assets/71364d39-767c-46d0-98e8-3d9ad668d28b" />


- **특징 및 주의점:**
    - **읽기 작업이 많을 때 병렬성을 유지하면서도 쓰기 시에만 독점권을 부여해 성능을 최적화**한다.
    - **반드시 직접 생성한 `Custom Concurrent Queue`에서 사용**해야 하며, 시스템 글로벌 큐에서는 효과가 없다. (독점할 수 없기 때문)
    - 독점 시에 `async`를 사용하는 이유?
        - Barrier가 설정된 쓰기 작업은 큐 내부에서 어차피 **독점적인 순서**를 보장받는다.
        따라서 호출한 스레드가 결과값을 즉시 반환받아야 하는 상황이 아니라면, 굳이 스레드를 차단(sync)하여 **컨텍스트 스위칭 비용**을 발생시킬 이유가 없기 때문이다.

### 4. DispatchSemaphore

- **Counting semaphore를 사용해 자원의 개수를 제한하여 접근을 관리하는 도구**
- **사용 방식**
    
    ```swift
    let semaphore = DispatchSemaphore(value: 1) // 1이면 이진 세마포어 (뮤텍스처럼 동작)
    
    func useResource() {
        semaphore.wait()   // 자원 요청 (값 감소)
        // 임계 구역 작업
        semaphore.signal() // 자원 반납 (값 증가)
    }
    ```
    
- **특징 및 주의점:**
    - 가용한 자원의 개수를 설정할 수 있어 **특정 개수만큼의 동시 접근을 허용할 때 유용**하다.
    - `semaphore.wait(timeout:)` 등 타임 아웃 기능을 위한 API를 제공한다.
    - 만약 semaphore 값이 1이고 특정 스레드가 wait을 호출했을 때, 굳이 커널 모드까지 가서 스레드를 차단하지 않아도 바로 자원을 사용할 수 있으므로 바로 **유저 모드에서 value를 0으로 바꾸고 임계 구역에 진입해 효율적**이다.
    - 그러나 자원이 없을 경우는 스레드를 즉시 'Sleep' 상태로 전환하므로 잦은 경합 시 컨텍스트 스위칭 비용이 크게 발생한다.

### 5. os_unfair_lock

- **iOS에서 가장 가볍고 빠른 저수준 동기화 API로, unfair-lock을 위한 스택 기반 구조체**
- **unfair-lock**
    - 전통적 락은 FIFO 방식으로 오래 기다린 스레드가 락을 먼저 획득하지만 이를 위한 시간 관리 비용이 많이 든다.
    - **불공정 락은 기존에 기다리던 스레드와 방금 막 접근한 스레드가 경쟁한다.**
    따라서 방금 막 접근한 스레드가 CPU를 이미 점유하고 있는 상태라면, 잠자다 깨어나는 스레드보다 훨씬 빠르게 락을 낚아챌 수 있다.
- **사용 방식**
    
    ```swift
    import os
    
    var lock = os_unfair_lock_s()
    
    func fastTask() {
        os_unfair_lock_lock(&lock)
        // 매우 짧은 작업 수행
        os_unfair_lock_unlock(&lock)
    }
    ```
    
- **특징 및 주의점:**
    - 짧은 시간동안 루프를 돌며 락 획득을 시도하다가, 락을 얻으면 컨텍스트 스위칭 없이 바로 작업을 시작하고, 시간 내에 락을 얻지 못하면 스레드를 대기 상태로 전환해 CPU 낭비를 막음으로써 성능을 최적화한다.
    - 락을 기다리는 높은 우선순위 스레드를 인지하여 우선순위 역전을 방지해 시스템 전체 성능 저하를 막는다.
    - 구조체 기반이므로 항상 메모리 주소값(`&`)을 넘겨야 하며, 사용법이 까다롭다.

### 6. Actor (Swift 5.5)

- **Swift 언어 차원에서 제공하는 데이터 격리 모델**
- **사용 방식**
    
    ```swift
    actor DataModel {
        private var value = 0
        func increment() { value += 1 } // 외부에서 접근할 때 직렬화 보장
    }
    
    // 외부 호출 시 (비동기적으로 실행됨을 명시)
    await dataModel.increment()
    ```
    
- **특징 및 주의점:**
    - **안전성:** **컴파일 타임에 데이터 레이스를 체크해주어 가장 안전하게 동기화를 보장**한다.
    - 스레드 폭발 위험 낮음:
    - **비의도적 직렬화:** 모든 비즈니스 로직을 액터에 담으면 병렬 처리가 불가능해져 오히려 성능 병목이 발생할 수 있다.
    - **홉핑 오버헤드:** `await` 지점에서 발생하는 실행 컨텍스트 전환(Thread Hopping) 비용을 고려해야 한다.

---

### 각 동기화 도구는 어떻게 선택해야할까?

| 도구 | ✅ 적합한 경우 | ❌ 부적합한 경우 | ⚠️ 주의점 |
| --- | --- | --- | --- |
| **NSLock** | Obj-C 혼용 환경 / 단순 임계 구역 보호 | 성능이 극도로 중요한 핫패스 / Swift concurrency와 혼용 | 동일 스레드에서 중첩 락 사용 시 데드락 발생 |
| **DispatchQueue (Serial)** | 락을 직접 다루지 않고 추상화된 순차 실행 / 작업 순서 보장 / 백그라운드 순차 I/O |  병렬 성능 극대화가 필요한 연산 | 메인 큐에서 `sync` 호출 / 동일 큐 내 재귀적 `sync` 호출 시 데드락 발생 |
| **Dispatch Barrier** | 읽기 多·쓰기 少 구조 (캐시, 공유 딕셔너리) / 읽기 병렬성 + 쓰기 일관성 동시 확보 | 읽기·쓰기 빈도가 비슷한 경우 | 글로벌 큐가 아닌 Custom concurrent 큐를 사용해야 함 |
| **DispatchSemaphore** | 동시 접근 수를 N개로 제한 / 비동기 작업을 동기적으로 대기 / 스레드 간 신호 전달 | 경합이 잦은 환경 (컨텍스트 스위칭 비용 급증) / `async/await` 환경 (스레드 폭발) | 세마포어 값을 올바르게 설정해야하고, `wait & signal` 연산 횟수를 맞춰야 함 |
| **os_unfair_lock** | 매우 짧고 빠른 임계 구역 / 성능 극도로 중요한 핫패스 / 우선순위 역전 방지 필요 | 임계 구역 내 작업이 긴 경우 / Obj-C 혼용 환경 / Swift concurrency와 혼용 | 락을 사용할 때는 항상 &연산자로 주소를 사용하거나, 전용 class 내부에 프로퍼티로 선언해 사용해야 함 |
| **Actor** | 컴파일 타임 데이터 레이스 방지 / Swift Concurrency 채택 프로젝트 / 상태 캡슐화 | 빈번한 짧은 동기화 (`await` 호핑 오버헤드) / GCD 레거시 혼용 | actor 내부에서 무거운 연산을 수행하면 안됨, actor 안에서 `await`을 사용할 경우 전/후 상태가 보장된다는 가정이 없음 |

---

### 그 밖의 동기화 도구

**NSRecursiveLock (재귀 락)**

- 동일한 스레드가 **이미 획득한 락을 중복해서 획득**하려고 할 때 발생하는 데드락을 방지할 수 있는 뮤텍스.
- 락을 소유한 스레드를 추적해 동일 스레드임을 확인하고 '재진입 횟수'를 카운팅하며 락을 얻은 횟수만큼 `unlock()`을 호출하면 완전히 해제한다.
- 언제 사용할까?
    - 재귀 함수 내에서 공유 자원을 수정해야 할 때
    - 메서드 A가 락을 잡고 있는데, 내부에서 락을 또 잡는 메서드 B를 호출할 때
- **주의점**
    - 일반 `NSLock`보다 재진입(Re-entrancy) 체크를 위한 로직이 추가되어 성능 오버헤드가 조금 더 크다.

**NSCondition (조건 변수)**

- 단순한 락을 넘어, **스레드 간의 실행 순서를 조율**하는 "신호등" 역할을 하는 Lock + Conditional variable
- 특정 조건이 만족될 때까지 스레드를 효율적으로 재웠다가, 조건이 만족되면 깨운다.
- **동작 원리**
    - `wait()`: 락을 해제함과 동시에 스레드를 대기 상태(Sleep)로 전환한다.
    - `signal()`: 대기 중인 스레드 중 하나를 깨운다.
    - 깨어난 스레드는 다시 락을 획득하고 작업을 재개한다.
- **언제 사용할까?**
    - **생산자-소비자 문제에서** Buffer가 비어있으면 소비자는 기다리고, 생산자가 물건을 넣은 뒤 신호를 보낼 때와 같이 특정 작업이 끝날 때까지 다른 스레드를 대기시켜야 할 때
    

**NSConditionLock (상태 기반 락)**

- NSCondition과 비슷하지만 특정 정수 값을 ‘조건’으로 두어 해당 값을 기준으로 락을 얻거나 해제할 수 있다.
- 따라서 사용자가 원하는 정수값을 설정하고, 그 값일 경우에만 락을 획득할 수 있다.
- 스레드가 실행되는 순서를 프로그래밍적으로 제어하고 싶을 때 유용하다.

```swift
let lock = NSConditionLock(condition: 0) // 초기값 0

// 스레드 A (데이터 다운로드)
func downloadTask() {
    lock.lock() // 아무 조건 없이 일단 잡음
    // 다운로드 중...
    lock.unlock(withCondition: 1) // 작업 완료 후 상태를 1로 변경
}

// 스레드 B (데이터 처리 - 상태가 1일 때만 진입 가능)
func processTask() {
    lock.lock(whenCondition: 1) // 상태가 1이 될 때까지 대기
    // 데이터 처리 로직
    lock.unlock(withCondition: 2) // 완료 후 상태를 2로 변경
}
```

 

**Atomic (원자성, iOS 18.0+)**

- 멀티스레드 환경에서 한 줄의 코드(`count += 1`)가 수행되는 동안 다른 스레드가 끼어들지 못함을 보장한다.
- Swift의 프로퍼티는 기본적으로 **Non-atomic하지만 Swift 6부터 Synchronization 프레임워크에 Atomic variable을 Atomic 타입으로 지원**하기 시작했다**.**

```swift
import Synchronization

// Atomic 변수 선언
let counter = Atomic<Int>(0)

// 1. 값 읽기 (Load)
let current = counter.load(ordering: .relaxed) // 메모리 재배치 관련 옵션

// 2. 값 저장 (Store)
counter.store(10, ordering: .relaxed)

// 3. 더하기 연산 (Add)
counter.add(1, ordering: .relaxed)

// 4. 비교 및 교체 (Compare and Swap)
// 현재 값이 10이면 20으로 변경
let (exchanged, original) = counter.compareExchange(expected: 10, desired: 20, ordering: .relaxed)
```

- Atomic 타입은 항상 `let`으로 선언되어야 하며, 모든 연산은 명시적이어야 한다.
- **Memory Ordering (메모리 순서)**
    
    위 코드의 `ordering` 파라미터는 현대 CPU의 최적화로 인해 발생하는 명령어 재배치를 어떻게 제어할지 결정한다.
    
    - **`.relaxed`**
        - 가장 빠르지만, 원자적 타입이 아닌 다른 메모리 연산과의 순서는 보장하지 않는다.
    - **`.acquiring / .releasing / .sequentiallyConsistent`**
        - 데이터 가시성을 보장해야 하는 복잡한 동기화 상황에서 사용 가능하다.
- 락을 사용하는 것보다 훨씬 저수준에서 CPU 명령어로 직접 처리되므로 매우 빠르지만(컨텍스트 스위칭 x), 단순한 값 변경 외의 복잡한 로직에는 적용하기 어렵다.

---

### 👀 동기화 도구 의사결정 리스트 (선택할 때 도움이 .. 🙏🏻 )

프로젝트가 **Swift concurrency 기반일 경우**

- 평범한 수준의 **동기화**가 필요하다면?
➡️ 우선 actor 검토 (컴파일 타임 안정성 챙기기)
- 임계 구역 연산이 매우 짧은데 actor의 hopping 비용이 오버헤드일만큼 실행 빈도가 높다? (핫패스)
➡️ os_unfair_lock (홉핑 비용 0, 스레드 폭발 가능성 낮음)

**Concurrency를 사용하지 않거나 Obj-C 혼용일 경우**

- Obj-C 혼용 코드 ➡️ NSLock (별도의 브리징 없이 바로 사용 가능)
- 공유 자원 접근 패턴 고려
    - 읽기가 많고 쓰기가 적다 ➡️ Dispatch Barrier (읽기는 병렬, 쓰기는 독점)
    - 읽기가 적고 쓰기가 많다 ➡️ Serial Queue (쓰기가 대부분이라면 대부분 직렬화됨, 가장 간단하고 가벼움)
        - ex) 이벤트 로그 수집 or 실시간 센서 데이터 버퍼
    - 비슷하다 ➡️ Barrier를 사용하는 이점이 없으므로 Serial queue or NSLock
- 동시 접근 스레드 수를 제한해야 할 경우 ➡️ DispatchSemaphore
- 재귀 호출 또는 중첩 락 ➡️ NSRecursiveLock

<img width="1440" height="1302" alt="image" src="https://github.com/user-attachments/assets/cba9c898-9c78-4bf2-9a1e-7aae8676219b" />


## 3. 의문 / 논점

### **1. actor는 만능일까?**

No, but why?

- **비결정적 실행 (Reentrancy):** `actor`의 메서드 내부에서 `await`을 호출하면, 해당 스레드는 제어권을 반납하고 다른 작업이 액터에 진입할 수 있게 된다.
즉, `await` 전후로 데이터의 상태가 달라질 수 있다는 점을 항상 인지해야 한다.
- **성능적 한계:** `await`을 통한 컨텍스트 전환(Hopping) 비용이 발생하므로, 극도로 짧은 연산을 수만 번 반복하는 곳에서는 `os_unfair_lock` 사용을 고려한다.

### **2. MainActor 남용 문제**

- **UI 프리징:** 모든 비즈니스 로직이나 데이터 처리를 `@MainActor`에서 수행하면, 결국 메인 스레드가 모든 짐을 짊어지게 되고, 이는 동기화 문제는 해결할지언정 사용자의 터치 반응성이나 애니메이션을 저해하는 결과를 초래할 수 있다.
- **책임 분리:** UI 업데이트와 직접 관련된 프로퍼티/메서드만 `MainActor`로 격리하고, 무거운 연산은 별도의 `actor`나 `Background thread`에서 처리한 뒤 결과만 전달해야 한다.

### **3. Swift 6.2에서 Default Actor Isolation을 MainActor로 둔 이유**

- [참고자료](https://www.avanderlee.com/concurrency/default-actor-isolation-in-swift-6-2/)
- **Swift 6.0의 문제** — 기본값이 `nonisolated`라서, 메인 스레드 중심으로 짜여진 기존 앱 코드와 컴파일러 가정이 어긋나 경고·에러가 연쇄 폭발
- **6.2의 해결** — 기본값을 `@MainActor`로 바꿔서 컴파일러 가정을 현실 코드베이스에 맞추었다. 이제 백그라운드가 필요한 곳만 명시적으로 `nonisolated`를 붙이면 된다.
    - **안전 우선 원칙:** 기본값을 `MainActor`로 두면 백그라운드 스레드에서 UI를 업데이트하는 것을 컴파일 타임에 감지할 수 있다.
    - **점진적 격리:** 일단 안전한 메인 스레드에 묶어두고, 성능 병목이 확인되는 부분만 비동기적으로 분리(Detached task 등)해 나가는 방식을 현대적이며 안전한 설계 방향으로 판단했기 때문이다.
- t**rade-off** — 마이그레이션 노이즈는 줄지만, `nonisolated`를 빠뜨리면 의도치 않게 무거운 작업이 메인 스레드에서 실행될 수 있다.

## 4. 참고 자료

Operating System Concepts ch6

https://green1229.tistory.com/500
