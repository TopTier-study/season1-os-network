# 1. 주제
### 운영체제에서 인터럽트의 역할과 과정을 이해해보자

</br>

# 핵심 개념 및 문제
## 핵심 개념
### 인터럽트(Interrupt)란?

인터럽트는 하드웨어 또는 소프트웨어가 CPU에게 현재 실행 중인 작업을 중단하고 특정 작업을 처리하도록 요청하는 신호입니다.

## 문제
### 인터럽트가 없다면 운영체제는 어떤 문제를 겪게 될까 ?
운영체제의 역할을 분석해볼 때 다중 프로그래밍에서 프로세스를 메모리에 올려놓고 I/O 작업 요청을 보내고 바로 다음 작업을 이어서 할 수 있었습니다. 그렇다면 I/O 작업이 끝났을 때를 CPU가 스스로 알려면 I/O 작업을 하고있는 하드웨어에 계속해서 완료여부를 확인하는 과정이 필요해집니다. 이는 CPU의 불필요한 작업이 더 생기는 것을 생각해볼 수 있습니다. 이걸 방지하기 위해서 CPU가 요청한 작업이 완료하면 바로 CPU에게 작업이 마쳤으니 다음 작업 진행해라고 보내는 신호가 인터럽트 입니다. 그렇다면 실제 인터럽트가 어떻게 되어있고 어떤 역할을 수행하는 지 살펴보겠습니다.


</br>

# 탐구내용
### 인터럽트 종류
먼저 인터럽트의 종류를 알아보겠습니다. 인터럽트는 크게 두개로 분리할 수 있습니다.
- **하드웨어 인터럽트** : 디스크, 키보드, 네트워크, 타이머 등 하드웨어에서 발생시키는 인터럽트이며 CPU는 이 신호를 받으면 현재 실행 중이던 작업을 잠시 중단하고 운영체제가 제공하는 인터럽트 처리 루틴을 실행한 후 다시 원래 작업으로 복귀합니다.
- **소프트웨어 인터럽트** : 프로그램 실행 중에 소프트웨어적으로 발생하는 인터럽트이며 대표적으로 시스템콜(system call)이 있습니다. 프로그램이 파일 접근이나 프로세스 생성과 같은 커널 기능을 사용하기 위해 의도적으로 인터럽트를 발생시킵니다.

### 인터럽트 처리 단계
1. 인터럽트 발생 (Interrupt Request)
- 장치 또는 소프트웨어가 CPU에 인터럽트 신호를 전달(단순한 전기 신호, 인터럽트 벡터 번호)
- 예: 
    - 디스크 I/O 완료
	- 네트워크 패킷 도착
	- 타이머 만료
	- 시스템 콜
2. 현재 상태 저장 (Context Save)
- CPU는 인터럽트 처리 후 원래 위치로 복귀하기 위해 현재 실행 중이던 프로그램의 상태를 보존
- 저장되는 정보:
	- Program Counter (PC)
	- CPU 레지스터 값
	- 상태 레지스터 (flags)
	- 스택 포인터
3. 인터럽트 핸들러 결정 (Vector Lookup)
- CPU는 인터럽트 벡터 테이블을 참조하여 해당 인터럽트를 처리할 함수 주소를 확인
4. 인터럽트 서비스 루틴 실행 (ISR Execution)
- CPU는 커널 모드로 전환한 후 인터럽트 핸들러 코드를 실행
- 처리 예:
	- 장치 상태 확인
	- 데이터 읽기
	- 프로세스 wakeup
	- 큐 업데이트
-  주의 :  인터럽트 핸들러는 가능한 짧아야 한다.(하지만 커널이 등록하는거라 개발자가 직접적으로 다루는 일은 거의 없다.)
5. 스케줄러 개입 가능 (Optional Scheduling)
- 인터럽트 처리 결과에 따라 스케줄러가 실행될 수 있습니다.
- 예:
    - I/O 완료 → 대기 프로세스 ready 상태
	- 더 높은 우선순위 프로세스 존재
    - 이 경우 프로세스가 I/O 작업을 요청할 때 커널은 해당 프로세스를 장치 요청과 연결된 커널 자료구조(대기 큐 등)에 등록하고 PCB의 상태를 blocked로 변경합니다. 이후 인터럽트가 발생하면 ISR은 이 커널 자료구조를 조회하여 완료된 요청과 연결된 프로세스를 찾아 깨우며, 그 결과 스케줄러가 개입하여 컨텍스트 스위칭이 발생할 수 있습니다. 이와 관련해서는 컨텍스트 스위칭 문서에서 추가로 탐구해보겠습니다.
6. 상태 복원 및 복귀 (Context Restore)
- CPU는 저장해 두었던 레지스터와 프로그램 카운터 값을 복원하고 인터럽트 발생 이전 위치로 복귀

</br>

# iOS 연결 지점
iOS로 넘어와서 인터럽트와 어떤지점이 연관되는지 살펴보겠습니다.
### 터치 이벤트
터치 이벤트 흐름을 os 관점에서 풀면, 화면을 터치했을 때 하드웨어 입력이 커널/드라이버 계층에서 처리된 뒤 사용자 공간으로 올라오고, 최종적으로 메인 스레드의 RunLoop가 이를 이벤트로 디스패치해서 UIResponder 체인으로 전달되면서 `touchBegan(_:with:)` 같은 콜백이 호출되는 구조입니다.
> **Port-Based Sources**  
> Cocoa and Core Foundation provide built-in support for creating port-based input sources using port-related objects and functions. For example, in Cocoa, you never have to create an input source directly at all. You simply create a port object and use the methods of NSPort to add that port to the run loop. The port object handles the creation and configuration of the needed input source for you.  
>  
> In Core Foundation, you must manually create both the port and its run loop source. In both cases, you use the functions associated with the port opaque type (CFMachPortRef, CFMessagePortRef, or CFSocketRef) to create the appropriate objects.  
>  
> For examples of how to set up and configure custom port-based sources, see *Configuring a Port-Based Input Source*.  
> — Apple, *Run Loop Management*
> https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/RunLoopManagement/RunLoopManagement.html

### 네트워크 async/await
네트워크 요청 또한 비동기적으로 수행되며, 완료 시 시스템이 콜백 또는 재개(resume)를 트리거합니다.
``` swift
let data = try await URLSession.shared.data(from: url)
```
이렇게 네트워크 요청을 진행하면 내부에서는 아래와 같이 작업을 진행하게됩니다.
```
네트워크 요청
→ 스레드 대기
→ NIC 인터럽트
→ 커널 wakeup
→ Task resume
```

### Thread blocking vs async 이해
그리고 Thread Blocking과 Async의 차이는 작업 완료를 기다리는 동안 스레드를 점유하느냐 여부에 있습니다. 
Blocking 방식에서는 스레드가 I/O 작업이 끝날 때까지 대기 상태로 머물며 실행을 멈추지만, Async 방식에서는 작업을 시작한 뒤 현재 스레드를 반환하고 다른 작업을 수행할 수 있도록 합니다.
 
두 방식 모두 내부적으로는 I/O 완료 시 하드웨어 인터럽트를 통해 커널이 이벤트를 전달받는 구조를 사용하지만, Blocking은 대기 중인 스레드를 깨우는 방식이고 Async는 중단된 작업(Task)을 재개(resume)하는 방식이라는 차이가 있고 따라서 Async는 동일한 스레드 수로 더 많은 작업을 처리할 수 있어 확장성과 성능 측면에서 유리합니다.

예를 들어 동기(Blocking) 네트워크 호출은 작업이 끝날 때까지 현재 스레드를 점유하고
```swift
// Blocking 예시
func fetchSync() throws -> Data {
    let url = URL(string: "https://~")!
    return try Data(contentsOf: url) // 완료될 때까지 현재 스레드 대기
}
```
반면 async/await을 사용하면 작업 진행 중 스레드를 점유하지 않고, 응답이 도착했을 때 시스템이 Task를 재개합니다.
```swift
// Async 예시
func fetchAsync() async throws -> Data {
    let url = URL(string: "https://~")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return data // 네트워크 완료 시 Task resume
}
```
즉, Blocking은 “스레드가 기다리는 모델”이고 Async는 “작업(Task)이 기다리는 모델”이라고 이해할 수 있습니다.

</br>

# 의문/논점

결국 인터럽트의 핵심 가치는 CPU가 “필요할 때만” 개입하도록 만들어 시스템 효율을 높인다는 점입니다. I/O 완료 여부를 CPU가 계속 확인하는 폴링 방식과 달리, 인터럽트 기반 방식은 장치가 완료 시점에 CPU에 신호를 보내므로 CPU 낭비를 줄이고 다른 프로세스 실행 기회를 확보하는 겁니다.

정리하면 인터럽트는 다음 세 가지를 가능하게 하는 운영체제의 기반 메커니즘입니다.
1. 비동기 I/O 처리: CPU와 장치 작업을 분리해 병렬적으로 진행
2. 빠른 반응성: 이벤트 발생 시 즉시 커널 개입 가능
3. 자원 효율 향상: 불필요한 대기/확인 루프 제거

즉, 다중 프로그래밍과 시분할 시스템이 실제 성능 이점을 내기 위해서는 인터럽트가 필수입니다.

## 추가 탐구 포인트
- 인터럽트가 너무 자주 발생하면 오히려 성능이 떨어지지 않을까?
- 폴링이 적합한 상황은 없나?
- 멀티 코어환경에서 인터럽트는 어떻게 처리되는가?
