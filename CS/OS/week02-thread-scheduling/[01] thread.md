# 스레드 등장 배경
### 학습 키워드
- 스레드
- C10K
- Swift Concurrency
- continuation
## 1. 핵심 개념
### 프로세스의 한계
- 무거움
	독립적인 가상 메모리 공간(Code, Data, Heap, Stack)을 갖기 때문에 Context Switching 단계에서 캐시와 TLB를 교체해야 하는 오버헤드가 발생.
- 통신
	프로세스는 기본적으로 독립되어있기 때문에 통신을 위해서는 복잡한 IPC 기법들이 필요. 파이프, 소켓, 공유 메모리 등은 시스템 콜을 사용해야하는 느린 과정.
- C10K 문제
	단일 서버가 10,000 이상의 클라이언트와 연결을 유지하며 통신을 할 수 있도록 네트워크 소켓 처리 성능을 최적화하는 문제. 1999년 Dan Kegel이 처음 제안.
	참고: https://oliveyoung.tech/2023-10-02/c10-problem/
	❗️C10K 문제는 프로세스 단위의 한계는 맞지만 그 해법은 멀티스레딩을 넘어 멀티플렉싱까지 언급되고는 한다.
### 경량 실행 단위(Light Weight Process)
== Thread
Code, Data, Heap은 공유.
Stack, PC, Register만 교체.
### 동시성 문제 발발
Heap, Data 영역을 공유하기 때문에 접근 순서에 따라 결과가 달라지는 동시성 문제가 발생.
## 2. 탐구 내용 (실무 / iOS 연결)
---
---
## 스레드란?
- 경량화된 프로세스.
- 프로세스 하나에 CPU 수행 단위만 여러 개 두는 것.
- CPU 이용의 기본 단위.
### 특징
- 같은 프로세스 내의 다른 스레드와 코드, 데이터 섹션, 열린 파일이나 신호와 같은 운영체제 자원을 공유.
- ID, PC, stack, 레지스터 집합으로 구성.
### 동기(Motivation)
예시)
	많은 클라이언트들이 접근할 수 있는 웹 서버에서, 전통적인 단일 스레드 프로세스라면, 각 클라이언트는 응답을 받기까지 긴 시간을 기다려야 한다.
	만일 별도의 프로세스를 만들어 해결할 경우 많은 리소스가 소모된다. 
	대신 스레드를 사용해 프로세스가 한 번에 하나 이상의 일을 수행하도록 한다. 

얼마나 많은 리소스 차이가 있는가.?
### 장점
- 응답성(responsiveness): 앱 일부가 block되어도 프로그램은 계속 수행되며 응답을 제공할 수 있다. 
- 자원 공유(resource sharing): 프로세스는 IPC 기법이 필요했지만 스레드는 자원과 메모리를 공유하기 때문에 협업이 용이하다.
- 경제성(economy): 프로세스 생성보다 스레드를 활용하는 것이 경제적이다.
	- solaris 운영체제 기준 생성, context switching 비용이 각각 30배, 5배.
- 규모 적응성(scalability): MP(multi processor) 환경에서 각 스레드가 다른 프로세서에서 실행 가능하다. 
## 다중 스레드 모델
### 커널 수준 스레드(Kernel-Level Thread)
OS가 만들고, OS가 스케줄링하는 진짜 스레드.
TCB가 생성되는 단위.
### 유저 수준 스레드(User-Level Thread)
OS는 모르게, 런타임 라이브러리가 알아서 쪼개어 쓰는 가짜 스레드.
또는 Green Thread.
언어의 런타임이나 라이브러리가 관리.
### N:N 모델
유저 수준 스레드와 커널 수준 스레드의 관계에 따른 모델 설명. 후술할 M:N 모델과는 달리 다음 용어들을 묶어 설명하기 위해 임의로 붙인 이름.
### 일대일 모델(One to One Model)
유저 수준 스레드가 만들어지면 그에 따라 커널 수준 스레드가 1대1로 생성되는 모델.
따라서 유저 수준 스레드의 의미가 없기 때문에 커널 수준 스레드로 볼 수 있다. 
- 장점
	- 스레드가 블로킹되더라도 커널이 Context Switching을 해줄 수 있어 멀티 코어를 잘 활용할 수 있다.
- 단점
	- Context Switching을 포함한 스레드 작업 시 커널 모드로 진입함에 따른 오버헤드. 
🍎 DispatchQueue.global()에서 작동하는 백그라운드 작업은 커널 수준 스레드(Mach Thread)에서 작동.
### N:1 모델(Many to One Model)
다수의 유저 수준 스레드를 하나의 커널 수준 스레드에 매핑.
- 장점
	- 커널 모드로 진입하지 않고 교체할 수 있어 가볍다.
- 단점
	- blocking 시스템 콜에 대해 프로세스 전체가 멈춘다.
### M:N 모델(Many to Many Model)
다수의 유저 수준 스레드가 다수의 커널 수준 스레드에서 작동한다.
🍎 Swift Concurrency는 코어 수 만큼의 커널 스레드에서 많은 수의 유저 수준 스레드를 작동시킨다.
## 암묵적 스레딩(Implicit Threading)
스레드의 생성, 관리 책임을 개발자 -> 컴파일러, 런타임 라이브러리에 넘기는 기법.
### 스레드 풀
일정한 수의 스레드를 미리 만들고, 풀에 작업을 요청하면 대기 중이던 스레드 하나가 깨어나 작업을 수행하고, 마치면 스레드 풀로 돌아온다.
### Grand Central Dispatch(GCD)
mac, iOS에서 개발자가 병렬로 실행될 코드 섹션을 식별할 수 있는 런타임 라이브러리, API, 언어 확장의 조합.
### 이외 
- Fork Join 
- OpenMP
# 참조
- https://imbf.github.io/computer-science(cs)/2020/10/14/Threads-and-Concurrency.html
---
---
WWDC_Swift Concurrency: Behind the Scene을 요약한 https://lsj8706.tistory.com/90를 참고함.
### 도입 배경
[[GCD(Grand Central Dispatch)]]는 개발자가 스레드를 직접 만들지 않고 Queue에 작업을 던지면 OS가 스레드 풀을 관리해주는 시스템이었다. 하지만 다음과 같은 한계가 존재했다.
- 스레드 폭발(Thread Explosion)
	상황 예시) 많은 작업이 대기하는 상황에서 스레드들이 대기 상태로 들어가며 CPU에 여유가 생기면 GCD는 스레드를 더 많들어 CPU의 작업량을 관리하려한다. 이 때 스레드가 무한정 많아질 수 있다. 
	메모리 스택이 많아지는 문제 및 엄청난 [[문맥 교환(Context Switching)]] 오버헤드가 발생할 수 있다. 
- 가독성 문제
	비동기 작업 후 @escaping 탈출 클로저를 이용하는 방식에서 콜백 지옥이 생기기 쉬우며 에러 처리가 복잡해졌다.
### Cooperative Thread Pool
- Swift Concurrency에서는 스레드 개수를 CPU 코어 수만큼만 유지한다.
- 각 작업은 스레드에 묶이지 않고 Task 단위로 관리한다.
- 스레드 양보(Yield): await을 만나 작업을 진행하지 않을 때, Task를 잠시 suspend하고 스레드는 다른 Task를 가져와 실행한다. 
- 스레드 개수가 고정되어 있기 때문에 OS 레벨의 Context Switching이 거의 발생하지 않는다. 대신 Swift 런타임이 가벼운 함수 호출 수준으로 Task만 교체한다. 
### Continuation
<img width="1280" height="667" alt="image" src="https://github.com/user-attachments/assets/d8f0e289-1c40-4053-9974-dd0ce8a33324" />

작업 추적을 위한 경량 객체. 
위에서 언급한 Task단위에 대한 실제 객체. 
### Contract
이러한 구현이 가능했던 것은 라이브러리었던 GCD와 다르게 Swift Concurrency는 언어의 일부이기 때문이다. 언어 차원에서 지원하는 스레드 기능이 스레드를 차단하지 않고 제어권만 Yield하는 구현이 가능해졌다. 
이것이 런타임 contract에 대한 이야기다.
#### await and non-blocking of threads
언어 수준에서 지원하는 기능 첫 번째.
<img width="1280" height="578" alt="image" src="https://github.com/user-attachments/assets/ce072c4d-35f4-456e-bd82-0ee04509e843" />

- 함수는 stack에 적재된다.
- id, article 변수는 for문 내에서 사용되기 때문에 스택에 저장된다.
<img width="1280" height="576" alt="image" src="https://github.com/user-attachments/assets/be0547f0-5fdc-46be-bb2b-6c9ec742b945" />

- async 함수 add는 호출될 때 Heap에 프레임을 생성한다.
- await을 만나 스레드를 Yield해야 되기 때문에 주요 변수를 Heap에 옮겨야한다.
- newArticles는 중단점 전에 생성되었지만, 중단점 이후에도 사용되는 변수이다. 따라서 Heap에 저장된다.
<img width="1280" height="582" alt="image" src="https://github.com/user-attachments/assets/9bc1fb90-c363-4474-b544-004055b0cc16" />

- save 함수가 실행되면 add의 스택 프레임이 save의 프레임으로 대체된다. 필요한 변수는 이미 Heap에 모두 저장되어있기 때문이다. 
- 차후 save의 연산이 끝나면, save용 스택 프레임이 다시 add로 대체된다.
#### Tracking of dependencies in Swift task model
언어 수준에서 지원하는 두 번째.
<img width="1280" height="641" alt="image" src="https://github.com/user-attachments/assets/e5e44644-2e52-4236-abe5-ec9e9c3c0bbd" />

- URLSession data task는 비동기 함수, 이후의 작업은 continuation으로 작동한다.
- continuation은 비동기 함수가 종료된 후에 실행할 수 있다.
- 이는 Swift concurrency runtime이 추적하는 디펜던시이다.
- 이러한 디펜던시 관계는 Swift 컴파일러와 런타임에 명시적으로 알려져 있다.
이러한 특성이 forward progress를 가능하게 함.
### 검토할 사항
- continuation 저장 등에 비용이 들기 때문에 너무 간단한 작업은 도입 비용이 더 클 수 있다.
- await 이전의 스레드와 continuation이 실행될 스레드가 다를 수 있다.
- 원자성이 보장되지 않을 수 있다.
- runtime contract를 고려해야 한다. 
	<img width="1280" height="599" alt="image" src="https://github.com/user-attachments/assets/4997446b-38e5-4387-aeea-82d9affacd28" />

	Actor, Task groups 등은 디펜던시가 컴파일 타임에 알려져 디버깅이 용이하다. 
	이후의 요소들은 사용에 주의가 필요하거나 swift concurrency와 함께 사용하기에 안전하지 않다. 
---
---
WWDC Meet async/await in Swift를 요약한 https://icksw.tistory.com/266를 참고함.
### 스레드 관리
- 일반적인 함수
	함수를 호출면 스레도 같이 넘겨줌. 함수가 정상적으로 종료되면 스레드를 호출자에게 넘겨줌. 
- 비동기 함수
	함수가 호출될 때 마찬가지로 스레드 제어권을 받음.
	await을 만나면 스레드를 반환함: 시스템에 반환.
	시스템은 스레드를 이용해 다른 작업을 수행. 
	어떤 시점에 시스템이 원래 함수에 스레드 제어권을 주고, 함수 실행을 마치면 그제야 호출자에게 스레드 권한을 돌려줌.

#### async/await 블록은 하나의 트랜잭션으로 실행되지 않는다?
await을 하면 스레드 제어권을 시스템에 Yield하고 Suspend한다. 이렇게 정지되어있는 동안 앱 상태가 변할 수 있음에 유의해야 한다.
### Suspend
- async 함수는 일시 정지할 수 있다.
- 일시 정지할 경우 호출자도 일시 정지한다. 따라서 호출자도 async로 정의되어있어야 한다.
- 비동기 함수에서 일시 정지 될 수 있는 위치를 알리는 방법이 await.
- 일시 정지되면 스레드가 시스템에 반환되어 앱 상태가 원하지 않게 변할 수 있다. 
- 비동기 함수가 다시 시작될 때 호출한 비동기 함수의 반환 결과가 호출자로 전달되고, await 다음부터 실행된다.
#### 그렇다면 async 컨텍스트가 아닌 곳에서는?
Task로 해당 부분을 감싸 비동기 호출을 할 수 있다.
- Task: 유저 수준 스레드
- Task가 작동하다 await을 만나는 것: 유저 수준 스레드가 동작하다 커널 수준 스레드를 다른 유저 수준 스레드가 사용할 수 있도록 하는 것.
- await: 유저 수준 스레드가 Yield 하는 행위를 유발하는 코드.
---
---
WWDC Explore structured concurrency in Swift를 요약한 https://velog.io/@yoosa3004/iOSWWDC-Explore-structured-concurrency-in-Swift를 참고함.
### Structured Programming
초기 프로그래밍 언어가 GOTO 명령어를 사용해 어떤 곳으로든 이동할 수 있어 복잡한 flow를 만들었던 것과 달리 구조적 프로그래밍을 적용하면 3가지 논리 구조만으로 복잡한 로직을 통제한다.
1. 순차(Sequence): 위에서부터 실행
2. 선택(Selection): if, switch문과 같이 특정 조건에 따라 실행 경로를 분기.
3. 반복(Iteration): 특정 조건이 만족될 때까지 코드 블록을 반복. (for, while)
구조적 프로그래밍의 적용으로 예측 가능성이 크게 상승.
#### 비동기 문법의 structured
기존의 클로저, Completion Handler, 파편화된 백그라운드 스레드들은 언제 시작해서 언제 끝나는지 추적이 불가능. 
구조적으로 만들겠다: 부모가 자식 작업들을 파생시켰다면 모든 자식 작업이 끝나야 본인도 종료될 수 있는 구조. 비동기의 scope를 만든다.
### Sequential Binding
await 방식. 작업을 순서대로 처리.
두 작업 사이에 연관성이 없는 스레드끼리 Yield하고, 결과를 받아올 때까지 뒷부분 코드는 실행되지 않음.
### Concurrent Binding
#### async let
의존성이 없는 독립적인 비동기 작업들을 병렬로 실행, 결과만 한 번에 모아서 기다리는 문법.
```swift
let (data, _) = try await URLSession.shared.data(for: request)
let image = UIImage(data: data)
```
```swift
async let (data, _) = URLSession.shared.data(for: request)

let image = try await UIImage(data: data)
```
위 코드의 전자는 Sequential Binding 방식, 후자는 Concurrent Binding 방식이다. 
async let을 사용하면 child Task가 생성되어 작동한다. parent Task는 변수에 우선 placeholder를 할당하고, 이 변수를 실제로 사용하는 곳에서 await을 걸어 작업이 끝날 때까지 기다린다.
#### structured인 이유
async let으로 선언된 Task는 부모 함수에 완벽히 종속된 Child Task이다. 부모가 Cancel되면 함께 Cancellation을 받고, 생명 주기가 하나로 묶인다.
**Task Tree**라는 계층 구조를 만들기 때문에 하위 Task가 모두 완료되어야만 상위 Task가 완료될 수 있다.
#### 프로세스 계층 구조와 비교
- 유사한 부분
	- OS가 fork()로 자식 프로세스 생성: async let으로 자식 Task 파생.
	- OS가 wait()으로 자식의 종료를 기다려 좀비 프로세스 방지: 부모 Task는 스코프를 벗어나기 전까지 반드시 모든 자식 Task의 종료를 await.
- 차이점
	- OS는 부모 프로세스가 죽으면 자식을 강제로 Terminate.
	- Task는 부모가 자식에게 Cancellation Flag만 남김. (취소 전파, Cancellation Propagation) 자식은 작업 중간중간 이를 직접 확인하고 자원을 정리한 뒤 스스로 정지.
		-> Cooperative Cancellation
		네트워크를 사용 중이었어서 소켓을 닫아야 한다거나, 트랜잭션 중이거나 하면 프로세스가 취소되는 것과는 달리 메모리를 공유하는 단위에서는 이를 정리하고 종료해야 함.
#### Task Group
async let은 Child Task를 생성할 때마다 문법을 작성하는 방식이었다.
Task Group은 Dynamic한 개수의 병렬 처리를 위한 문법이다.
```swift
// generated by gemini
// 수십 개의 썸네일 이미지를 병렬로 다운받는 구조적 동시성 
func fetchAllThumbnails(urls: [URL]) await -> [UIImage] { 
	// 1. TaskGroup이라는 안전한 울타리를 엽니다. 
	await withTaskGroup(of: UIImage?.self) { group in 
		var downloadedImages: [UIImage] = [] 
		
		// 2. 배열을 돌며 자식 Task를 병렬로 마구 던집니다. (동적 파생) 
		for url in urls { 
			group.addTask { 
				return await downloadImage(from: url) 
			} 
		} 
		
		// 3. 누가 먼저 끝날지 모르지만, 완료되는 족족(for await) 받아서 배열에 넣습니다. 
		for await image in group { 
			if let image = image { 
				downloadedImages.append(image) 
			} 
		}
		
		 // 4. 모든 자식이 끝나야 이 울타리(Scope)가 종료되며 결과가 반환됩니다. 
		 return downloadedImages 
	 } 
 }

```
❗️withTaskGroup, withThrowingTaskGroup
	withTaskGroup: 실패한 Task는 기본값으로 처리해야 함.
	withThrowingTaskGroup: 실패하면 에러를 던지고 중단시킬 수 있음. 중단하면  Cancellation 전파.

⚠️ Task 생성은 @Sendable 해야한다.
### Unstructured Task
- Task{} 문법으로 직접 생성된 Task에 대한 이야기다.
- 현재 Actor에서 실행되도록 스케줄링된다. 
- 부모의 생명 주기를 넘어설 수 있다. 오히려 자동으로 관리(Cancel)되지 않으며 개발자가 변수에 넣고 관리해야한다.
- non-async 함수에서도 생성 가능.
### Detached Tasks
Task, async let, task group 모두 actor 수준을 상속한다.
이를 상속하지 않기 위해서는 Detached Task를 사용해야한다.
## 3. 의문 / 논점 
- 실제 코딩에서 우리가 신경쓸 수 있는 지점들은?
