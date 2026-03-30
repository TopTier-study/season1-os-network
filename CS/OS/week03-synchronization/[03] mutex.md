# Mutex
### 학습 키워드
- lock
- Mutex

## 1. 핵심 개념
프로세스 간 메시지를 전송하거나 공유 메모리를 통해 공유된 자원에 여러 개의 프로세스가 동시에 접근하면 Critical Section에 문제가 발생할 수 있다. 이를 해결하기 위하여 데이터를 한 번에 하나의 프로세스/스레드만 접근할 수 있도록 제한을 두는 동기화 방식이 필요하다. 이때 사용되는 **동기화 도구**에는 **Mutex**와 **Semaphore**가 있다.
### Mutex
: 공유 자원에 동시에 접근하지 못하도록 하는 장치
(한 번에 하나의 스레드만 Critical Section에 들어갈 수 있도록 함.)

- Critical Section을 가진 스레드의 실행 시간이 서로 겹치지 않고 각각 단독으로 실행될 수 있도록(= **상호배제**) 하는 기술이다.
- Key를 기반으로 한 상호배제 기법
  - **Key에 해당하는 객체를 소유한 스레드/프로세스만이** 공유 자원에 접근 가능하도록 함.
  - 예시) 식당에 화장실이 하나, 화장실 키를 소유한 사람만이 화장실에 들어갈 수 있음, 키가 없는 사람은 기다렸다가 들어가야 함.
- **세마포어와의 차이점**:
  - **세마포어**: 공유 자원에 접근할 수 있는 프로세스의 **최대 허용치**만큼 동시에 사용자가 접근 가능
    - 예시) 화장실이 여러 개인 식당
  1. 동작 모델의 차이
     - 뮤텍스는 자원 하나에 대한 배타적 소유로 상호배제 관리
     - 세마포어는 현재 동시에 접근 가능한 수를 카운터로 관리
  2. 자원 소유 여부 (뮤텍스는 자원 소유 가능, 세마포어는 불가능)
     - 소유권 개념 = 뮤텍스를 잠근 스레드만이 뮤텍스를 해제할 수 있다
     - 즉 뮤텍스는 소유하고 있는 스레드만이 이 뮤텍스 해제 가능 (세마포어는 소유하지 않는 스레드가 세마포어 해제 가능)
- **세마포어와의 공통점**: 둘 다 공유 자원 접근을 제어하는 데 유용하지만 잘못된 설계나 사용까지 막아주지 않으므로 데이터 무결성을 항상 보장할 수는 없으며 모든 교착 상태를 해결하지는 못함. 그러나 이에 매커니즘을 더해 성능을 개선하는 것이 중요.

#### 예시
```swift
let lock = NSLock()
var counter = 0

func increment() {
    lock.lock()
    counter += 1
    lock.unlock()
}
```
- 동작 방식
  1. lock 요청
  2. lock이 비어 있으면 획득
     - 다른 스레드가 lock을 가지고 있으면 기다림
  3. Critical Section 실행
     - 뮤텍스를 잠그고 자원에 접근하여 읽기 / 쓰기 작업 수행
  4. lock 해제
     - 다른 스레드가 해당 공유 자원에 접근할 수 있도록 함.

## 2. 탐구 내용 (실무 / iOS 연결)

### Lock이 필요한 이유
동시성 문제(race condition)는 단순히 여러 스레드가 동시에 실행된다는 것이 아니라 **여러 단계로 이루어진 연산이 중간에 끼어들어 잘못된 결과가 나오는 것**이다.

#### 예시
swift 코드: `counter += 1`

실제 CPU에서 수행되는 단계
```
1. counter 값을 읽는다.
2. 1을 더한다.
3. 결과를 다시 저장한다.
```

두 개의 스레드가 동시에 실행되면서 race condition이 발생하는 예시
```
Thread A: counter = 5 읽음
Thread B: counter = 5 읽음
Thread A: 6 저장
Thread B: 6 저장

// 결과
정상 결과: 7
실제 결과: 6 (동시성 문제로 인한 잘못된 결과 = race condition)
```

**연산이 원자적으로 실행되지 않기 때문에** 여러 실행 흐름이 서로 끼어들며 잘못된 결과가 발생할 수 있고, 이를 막기 위하여 **Critical Section(공유 자원 접근 구간)을 보호**해야 한다.
이때 보호 장치가 **Lock**이다.

### Spinlock
: 가장 단순한 lock 방식

- lock이 풀릴 때까지 계속 확인하면서 기다리는 방식
  ```
  while(lock == locked) {
      계속 확인		// lock 풀렸나? lock 풀렸나? lock 풀렸나? lock 풀렸나? ...
  }
  ```
  - 계속 CPU를 사용하면서 기다림.
- 장점: 단순하고 매우 빠름.
  - 스레드 sleep이 없고, 컨텍스트 스위칭이 없고, 커널 개입도 없기 때문이다.
  - -> **lock 시간이 매우 짧을 때 빠름.**
- 단점: lock 시간이 길어지면 CPU 낭비로 이어짐.
  - 예시) 스레드 A가 5ms 동안 lock을 사용하면 스레드 B는 그동안 spin하며 CPU가 낭비됨.

#### OSSpinLock
: Apple이 이전에 제공하던 spinlock

```swift
var lock = OSSpinLock()

OSSpinLockLock(&lock)
counter += 1
OSSpinLockUnlock(&lock)
```

문제: **priority inversion**(우선순위 역전)
우선순위: `task 1 > task 2`일 때

1. task 2이 공유 자원에 접근하기 위하여 lock 획득
2. 스케줄러에 의해 우선 순위가 더 높은 task 1이 수행됨.
3. task 1은 task 2이 가진 lock을 획득하기 위하여 기다림. (spin)
4. lock을 풀어야 하는 task 2가 실행 기회를 얻지 못함.

-> 이러한 문제로 인해 OSSpinLock은 deprecated됨.

#### os_unfair_lock
이후 Apple이 OSSpinLock 대신 만든 것이 os_unfair_lock이다. (이건 spinlock 아님)

- **먼저 기다린 스레드가 반드시 먼저 락을 얻는 공정성을 보장하지 않음.**
- 공정성보다 성능을 우선하는 방향으로 설계되어 있음.
- 동작
  - lock 획득 시도
    - 성공 -> 실행
    - 실패 -> 스레드 sleep (운영체제가 스레드 재움)
- 장점
  - CPU 낭비 X
  - priority inversion 완화

### Mutex 내부 동작
**CPU의 원자적 연산**을 사용하여 구현됨.

#### 알고리즘 조건
- **상호 배제**: 한 번에 하나의 실행 흐름만 Critical Section에 들어갈 수 있어야 함.
- **진행 보장**: Critical Section이 비어 있다면 누군가는 반드시 들어갈 수 있어야 함. (= 시스템이 멈추면 X)
- **유한 대기**: 특정 실행 흐름이 무한히 기다리면 안됨. (기아 현상)

#### 대표적 원자적 연산
- compare-and-swap: 현재 값이 예상한 값과 같을 때만 새 값으로 바꾸는 연산
  ```
    lock 값이 0이면
    → 1로 바꾸고 성공
    이미 1이면
    → 실패
  ```
- test-and-set: 기존 값을 읽으면서 동시에 lock 값을 설정하는 연산
- fetch-and-add: 현재 값을 읽고 특정 값을 더한 뒤 다시 저장하는 연산

### Mutex 성능
Mutex는 안전하지만 비용이 존재한다.

#### 1) Lock 경합
여러 스레드가 하나의 lock을 기다린다면 **결국 순차 실행을 하게 되므로 프로그램의 병렬성이 사라진다.**

#### 2) Context Switching 비용
- lock을 기다리는 동안
  - 스레드는 잠자기
  - 운영체제는 문맥 교환 실행 (CPU 캐시, TLB, 파이프라인 영향 -> 비용 소모 ↑)
    - 현재 스레드 상태 저장
    - 다른 스레드 실행
    - 다시 복구

#### 3) 캐시 문제 (멀티코어)
멀티코어 환경에서는 lock 변수 자체가 성능 문제를 만들기도 한다.

- lock 변수 = 여러 CPU 코어가 동시에 접근하는 데이터
- **캐시 라인 이동(cache line bouncing)** 발생할 수 있음.
  - 각 CPU 코어는 본인만의 캐시를 가지고 있고, 여러 코어가 같은 lock 변수를 갱신하면 캐시 일관성을 맞추기 위해 캐시 라인이 코어 사이를 오가게 된다. (이게 cache line bouncing)
    1. Core1이 lock 수정
    2. Core2 캐시 무효화
    3. Core2 다시 메모리에서 읽음
    4. Core2 수정
    5. Core1 캐시 무효화
  - lock이 있는 프로그램에서 성능이 떨어지는 이유 중 하나

### iOS에서 Queue 기반 동기화를 자주 사용하는 이유
iOS에서는 전통적인 lock 방식보다 **Queue 기반 방식**을 더 많이 사용한다.

#### 예시 코드
```swift
let queue = DispatchQueue(label: "state.queue")
var counter = 0

func increment() {
    queue.sync {
        counter += 1
    }
}
```
- lock을 사용하지 않음.
- 그러나 여기서 큐는 **시리얼 큐**이기 때문에 **한 번에 하나의 작업만 실행**
- 장점
  - lock / unlock 실수 방지 가능
  - 코드 구조 단순
- 그러므로 iOS에서는 공유 데이터를 시리얼 큐로 보호하는 방식을 자주 사용한다.

### Swift Concurrency의 Actor
`Actor = 상태 + 접근 제한` 구조

- Mutex는 여러 스레드가 경쟁하는 구조이지만 Actor는 작업들이 줄서서 실행되는 구조이기 때문에 경쟁 자체가 줄어든다는 의미가 있다.
- Swift Actor: **reentrant actor** (reentrancy = Actor 함수 안에서 **await 발생 시 현재 실행이 중단되고 다른 작업이 들어와서 실행될 수 있음**.)
  ```swift
  // 예시 코드
  actor BankAccount {
  
    var balance = 100
  
    func withdraw(amount: Int) async {
        if balance >= amount {
            await networkCall()
            balance -= amount
        }
     }
  }
  ```
  - 즉 Actor는 **상태에 대한 동시 접근을 직렬화하여 데이터 레이스를 줄여주지만** **await를 사이에 둔 논리적 일관성까지 자동으로 보장해주지는 않는다.**

### iOS에서의 동기화 도구
- 낮은 수준
  - pthread_mutex
  - os_unfair_lock
- 중간 수준
  - NSLock
  - DispatchQueue
- 최신 방식
  - Swift Concurrency
  - Actor

### Swift의 Mutex
> [Modern Swift Lock: Mutex & the Synchronization Framework](https://www.avanderlee.com/concurrency/modern-swift-lock-mutex-the-synchronization-framework/)
> https://medium.com/@swagati/%EB%AE%A4%ED%85%8D%EC%8A%A4-swift-concurrency-13-e246e5f5fd56

기존의 Swift에서는 따로 뮤텍스를 제공하지 않았다.
그러나 Swift 6 / iOS 18에서 Synchronization 프레임워크가 도입되면서 Mutex 타입이 추가되었다.
(WWDC 24에서 발표)

새로운 락 알고리즘을 직접 만든 것이라기보다 기존 OS 수준의 락을 Swift에서 더 안전하게 사용할 수 있도록 감싼 API(래퍼)라고 볼 수 있다.
```
[ 구조 ]
Swift Mutex
↓
os_unfair_lock
↓
커널 스케줄러
↓
CPU atomic instruction
```
즉 실제로 경쟁을 해결하는 것은 os_unfair_lock이다.

- **os_unfair_lock이 하는 일**
  1. CPU의 원자적 연산으로 락 획득 시도
  2. 성공하면 바로 Critical Section 실행
  3. 실패하면 커널이 스레드를 잠재움
  4. 락이 풀리면 스케줄러가 다시 깨움

#### 특징
* Swift 6 Synchronization Framework에서 공식 도입
* closure 기반 접근(withLock)
  ```swift
  import Synchronization
  
  // 뮤텍스 객체 생성
  let mutex = Mutex<Int>(0)	// 내부 데이터 보호
  
  // 데이터 접근하기 
  mutex.withLock { value in
      value += 1
  }
  ```
- 데이터 접근 시 모든 접근이 **withLock 클로저** 내부에서만 가능
  - lock -> 작업 수행 -> unlock 과정 자동 처리
* 저수준 동기화 기본 도구 (low-level synchronization primitive)
  * 동시성을 제어하는 가장 기본적인 수준의 도구
  * 동작이 단순하고 직접 경쟁을 제어함.
  * 성능 최적화에 유리
* Actor보다 가볍고 세밀한 제어 가능

#### 사용하는 경우
- 매우 짧은 공유 상태를 보호하고자 하는 경우
- 동기 코드 기반 API인 경우
- actor로 바꾸기엔 과한 저수준의 자료구조인 경우
- 성능이 민감한 경우

#### 단점
* deadlock 가능
* 병렬성 감소

#### Mutex vs Actor
- Mutex = 저수준 동기화
  - 동기 코드에서도 사용 가능
  - 오버헤드가 낮음
  - 세밀 제어 가능
- Actor = 구조적 동시성
  - 메시지 기반 실행
  - 비동기 호출 필요
  - isolation 제공

**Actor는 안전하지만 추가적인 오버헤드가 발생할 수 있고 설계 변경이 필요하기 때문에** 보다 가벼운 방식인 Mutex를 사용하여 동기화를 적용할 수 있다.

## 3. 의문 / 논점 
### lock vs GCD vs Swift Concurrency 차이?
: **같은 문제를 서로 다른 높이에서 푸는 도구**

* **lock**: 여러 실행 흐름이 같은 메모리를 직접 만질 수 있고, 그걸 **개발자가 lock으로 보호**하여 공유 데이터 접근을 직접 잠근다.
* **GCD**: 작업을 queue에 넣고 **queue가 실행 순서와 동시성 정도를 관리**한다.
* **Swift Concurrency**: async/await, Task, Actor를 통해 **언어와 런타임이 동시성 구조를 더 높은 수준에서 관리**한다.

-> **동시성을 어디서 통제하느냐**의 차이를 가짐.


#### a. 구조 차이

1) **lock 기반 구조**
- 가장 전통적인 방식
- ’접근 순간만 잠그기’
```
여러 스레드
↓
공유 데이터
↓
lock으로 보호
```

```swift
final class Counter {
    private let lock = NSLock()
    private var value = 0

    func increment() {
        lock.lock()
        value += 1
        lock.unlock()
    }

    func currentValue() -> Int {
        lock.lock()
        let result = value
        lock.unlock()
        return result
    }
}
```
* 데이터는 그냥 공유되어 있음.
* 여러 스레드가 접근 가능
* 대신 critical section만 잠금.

-> **공유 메모리 + 수동 보호** 모델 (**경쟁이 이미 존재하고, 그 경쟁을 제어**하는 방식)

2) **GCD 구조**
- 데이터를 lock으로 직접 잠그지 않고 **특정 queue에서만 접근하게 만드는 방식**
- ’작업을 queue에 넣어서 실행 순서를 통제’
```
여러 작업
↓
DispatchQueue
↓
순차 또는 병렬 실행
```

```swift
final class Counter {
    private let queue = DispatchQueue(label: "counter.queue")
    private var value = 0

    func increment() {
        queue.sync {
            value += 1
        }
    }

    func currentValue() -> Int {
        queue.sync {
            value
        }
    }
}
```
- lock이 없음.
- 대신 serial queue가 한 번에 하나의 작업만 실행하므로 결과적으로 뮤텍스처럼 동작

-> **공유 메모리를 직접 잠그기보다 실행 컨텍스트를 제한** (**경쟁 자체를 줄이는 방향**)

**3) Swift Concurrency 구조**
- 더 고수준 레벨
```
외부에서 actor 상태 직접 접근 불가
↓
actor method로만 접근
↓
actor가 순차 처리
```

```swift
actor Counter {
    private var value = 0

    func increment() {
        value += 1
    }

    func currentValue() -> Int {
        value
    }
}

// 사용하기
let counter = Counter()
await counter.increment()
let value = await counter.currentValue()
```
* lock을 직접 다루지 않음.
* queue도 직접적으로 드러나지 않음.
* actor isolation과 task 모델이 중심

-> **구조적 동시성 + 상태 격리** 모델 (**공유 상태를 구조적으로 격리**)


#### b. 개발자가 관리하는 것들
1) **lock**에서 개발자가 직접 관리하는 것
   - 가장 많음.
     * lock / unlock 시점
     * lock 범위
     * lock 순서
     * deadlock 위험
     * contention
   - 실수 여지가 큼.

2) **GCD**에서 개발자가 관리하는 것
   - lock보다 조금 적음.	
     * 어떤 queue를 쓸지
     * serial / concurrent 선택
     * sync / async 선택
     * barrier 필요 여부
   - lock보다 안전하지만 설계 판단이 필요

3) **Swift Concurrency**에서 개발자가 관리하는 것
   - 더 적음.
     * 어떤 작업을 async로 만들지
     * actor로 격리할지
     * task 구조를 어떻게 가져갈지
     * 어디서 await할지
   - 즉 저수준 제어는 줄고 **동시성 모델링**을 신경쓰게 됨.


#### c. 성능 관점 차이
1) **lock**
장점
* 매우 가볍게 쓸 수 있다.
* 짧은 critical section에 빠를 수 있다.

단점
* contention이 생기면 성능이 급격히 나빠질 수 있다.
* 캐시 라인 이동, context switch, priority inversion 같은 문제와 연결된다.

2) **GCD**
장점
* thread pool 기반이라 스레드 직접 관리보다 효율적이다.
* queue 기반이라 설계가 비교적 단순하다.

단점
* sync/async를 잘못 쓰면 deadlock 가능
* queue hop이 많아질 수 있다.
* 상태 보호를 queue 설계에 의존한다.

3) **Swift Concurrency**
장점
* 코드 가독성이 좋다.
* 비동기 흐름이 직선적으로 보인다.
* actor로 data race를 줄이기 쉽다.
* 취소, task group, structured concurrency 같은 기능이 있다.

단점
* actor hop, await 지점, reentrancy 이해가 필요하다.
* 저수준 성능 제어는 lock보다 덜 직접적이다.
* 기존 GCD/콜백 코드와 섞을 때 생각할 게 많다.
