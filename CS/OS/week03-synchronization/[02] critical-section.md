# Critical Section
### 학습 키워드
- 동기화
- 임계 구역(Critical Section)
## 1. 핵심 개념
### 동기화
프로세스 사이의 수행 시기를 맞추는 것.
- 실행 순서 제어
- 상호 배제: 동시에 접근해서는 안 되는 자원에 대한 컨트롤
### 임계 구역(Critical Section)
여러 스레드가 공유 메모리에 접근하여 데이터를 변경하는 코드 블록.
#### 해결 조건
- 상호 배제: 한 프로세스가 임계 구역에 진입했다면, 다른 프로세스는 임계 구역에 들어갈 수 없다.
- 진행: 임계 구역에 어떤 프로세스도 진입하지 않았다면 임계 구역에 진입하고자 하는 프로세스는 들어갈 수 이써야 한다.
- 유한 대기: 한 프로세스가 임계 구역에 진입하고 싶다면 그 프로세스는 언젠가는 임계 구역에 들어올 수 있어야 한다.(무한 대기 방지)
### 동기화 기법
#### 뮤텍스 락(Mutex lock)
변수 lock을 acquire 함수로 잠그거나, release 함수로 해제하여 동기화를 수행한다.
- busy wait 문제: 임계 구역이 잠겨있을 경우 lock이 해제될 때까지 쉼 없이 반복하며 확인하는 것.
#### 세마포어(Semaphore)
lock 대신 변수를 사용하여 자원이 여러 개인 상황에 대응할 수 있다.
전역 변수 S, wait 함수, signal 함수로 구현된다.
자원의 개수가 S에 기록되며 wait()을 통해 임계 구역에 진입하거나 자원을 대기한다. signal()을 통해 자원을 해제할 수 있다. 
busy wait 문제를 막기 위해 대기 큐 개념을 도입한다. 자원이 없을 경우 대기 큐에 들어가며, signal 함수가 이를 준비 큐로 이동시킬 수 있다.
#### 모니터
공유 자원과 접근 인터페이스를 묶어 관리.
자원에 접근하는 프로세스를 큐에서 관리하고, 삽입된 순서대로 자원을 사용한다. 
## 2. 탐구 내용 (실무 / iOS 연결)
### Actor
WWDC Protect Mutable State with Swift Actors 요약인 https://medium.com/daily-monster/wwdc21-protect-mutable-state-with-swift-actors-%EC%9A%94%EC%95%BD-e55d755e9953를 참고함.
#### 배경
Data Race가 발생하는 조건: 두 스레드가 하나의 변수에 접근하는데, 둘 중 하나 이상이 쓰기 작업일 때.
Shared Mutable State: 공유되면서 변경 가능한 자원. Data Race가 발생하는 조건이다. 값 타입을 사용하면 공유되지 않기 때문에 Data Race가 일어나지 않는다.
	하지만 공유가 필요한 상황에는?
공유가 되는 자원에는 동기화 기법을 적용하여 안전하게 접근해야 한다. Actor는 이러한 동기화 문제를 해결하기 위해 탄생한 기법 중 하나다.
#### 사용 방법
```swift
actor Counter {  
	var value = 0  
	  
	func increment() -> Int {  
		value = value + 1  
		return value  
	}  
}
```
struct와 같은 타입으로 사용하면 된다.
외부에서 actor를 호출할 때는 actor가 사용 중일 경우 스레드를 양보할 수 있도록 비동기식으로 호출해야 한다.
```swift
Task.detached {
	await counter.increment()
}
```
#### 기본 사항
- Actors provides synchronization for shared mutable state
- Actors isolate their state from the rest of the program
	- All access to the state goes through the actor
	- The actor ensures mutually-exclusive access to its state
인스턴스 데이터 분리, 동기화된 접근 보장.
#### Actor reentrancy
actor는 하나의 스레드만 점유할 수 있으나, await 코드를 사용하여 suspend 될 경우 계속 점유하지 않고 다른 스레드(코드)가 진입할 수 있다. 
재진입은 deadlock이나 긴 접근 대기를 방지한다는 점에서 긍정적이나, 이로 인해 예상치 못한 순서로 코드가 실행될 수 있음에 주의해야 한다.
#### nonisolated
nonisolated가 붙은 함수는 actor 내부에서 작성되어 있더라도, 외부에서 await 없이 일반 동기 함수 처럼 호출할 수 있다. 
```swift
actor LibraryAccount{
		let idNumber: Int
		var booksOnLoan: [Book] = []
}

extension LibraryAccount: Hashable {
	nonisolated func hash(into hasher: inout Hasher) {
		hasher.combine(idNumber)
	}
}
```
위 예시에서, actor의 Hashable을 구현하고있다. 이때 hash 함수는 actor 내부에 있는 형태이지만 언제든지 actor 외부에서 호출될 수 있다. 이러한 경우에 nonisolated를 사용한다.
nonisolated가 붙으면 booksOnLoan 같은 가변 변수에 접근할 수 없다.
#### Sendable
[[(iOS)Sendable]]
만약 actor가 class를 가지고 있고, 외부에서 이에 대한 참조를 얻는다면 이 class는 쉽게 경쟁 상태에 놓이게 된다.
이러한 문제를 방지하기 위해 actor 외부와 내부가 데이터를 주고받을 때는 sendable한 타입만 주고받을 수 있다.
함수 역시 sendable 할 수 있다. 이 때 sendable synchronous 클로저는 actor-isolated 할 수 없다. 클로저가 actor 외부에서 실행되면 actor로 진입을 동기적으로 할 수 없기 때문이다.
#### MainActor
- Main thread: UI 렌더링, 이벤트 처리를 하는 메인 runloop가 동작하는 스레드.
	메인 스레드의 역할을 가볍게 해주기 위해선 외의 작업은 다른 스레드에서 진행하다 `DispatchQueue.main.async` 등을 이용해 UI 작업만 메인 스레드로 넘겨야 한다.
main actor는 해당 코드가 메인 스레드에서 동작함을 보장해주는 코드이다.
### Critical Section 찾기
#### Swift Compiler와 Strict Concurrency Checking 옵션
<img width="1948" height="982" alt="image" src="https://github.com/user-attachments/assets/f87f080a-5346-417c-a867-1d7a2b00083f" />

위 사진은 간단하게 Race Condition을 유발할 수 있는 코드를 작성한 것이다. 
이 때 두 가지 오류가 발생하는데 첫 번째는 Strict Concurrency checking 옵션이 없어도, 두 번째는 켰을 때만 발견된 오류이다.
- Main actor-isolated let 'account' cannot be accessed from outside of the actor; this is an error in the Swift 6 language mode
	- class가 Main actor 위에 있지만 다른 스레드 위에서 실행될 group task를 통해 동기적으로 호출하기 때문에 발생하는 에러. 
- Non-Sendable type 'BankAccount' of let 'account' cannot exit main actor-isolated context; this is an error in the Swift 6 language mode
	- BankAccount가 non-sendable인데 main actor 밖에서 작동하는 코드를 썼기 때문에 발생하는 에러.
Strict Concurrency Checking 옵션을 기본값인 minimal으로 했을 때와 complete으로 했을 때 차이점을 확인할 수 있었다.
#### Thread Sanitizer
<img width="1970" height="394" alt="image" src="https://github.com/user-attachments/assets/3a7c075f-56fc-4509-af72-aaf89cf7be65" />

- Edit Scheme -> Diagnostics -> Thread Sanitizer 옵션
백그라운드에서 메모리 접근을 감시하여 Data Race가 발생하면 경고를 보라색으로 띄워준다.
## 3. 의문 / 논점

## 4. 참고 자료
