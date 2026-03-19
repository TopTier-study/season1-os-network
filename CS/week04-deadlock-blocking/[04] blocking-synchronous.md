# Blocking/Synchronous
### 학습 키워드
- Blocking/Non-Blocking
- Sync/Async
- Multiplexing
## 1. 핵심 개념
### Blocking, Non-blocking
- Blocking
	Callee가 작업을 마칠 때까지 제어권을 가지고 있어 Caller에게 제어권을 바로 돌려주지 않는 방식.
	Caller 입장에서는 자신의 제어권을 OS에 반납하고 Blocked 상태로 전환되어 실행을 멈추는 현상.
- Non-blocking
	Callee가 자신의 일을 끝마치지 않아도 제어권을 Caller에게 반환.
### Sync, Async와 관계
Sync와 Async는 상호 배제, 실행 순서로도 설명할 수 있지만 여기서는 결과에 대한 관심 여부로 설명한다. 
- Sync: 결과에 관심을 갖는 경우.
- Async: 결과에 관심을 갖지 않는 경우.
Blocking, Non-blocking은 Sync, Async에 대해 각각 적용 가능하기 때문에 4가지 경우의 수가 생긴다.
- Blocking & Sync
	호출이 일어나면 Caller는 Callee의 작업이 끝날 때까지 기다린다.
- Non-blocking & Async
	Caller는 호출 후 자신의 작업을 계속 수행한다. Callee는 작업을 마치면 반환한다.
- Non-blocking & Sync
	Caller는 호출 후 자신의 작업을 계속 수행하지만 작업 결과를 계속 확인한다.
	Polling 방식.
- Blocking & Async
	Callee는 자신의 작업이 완료되는대로 결과를 제공한다. Caller는 결과가 오기까지 대기한다. 언뜻 Blocking & Sync 조합과 설명이 유사하거나, 괴상한 조합처럼 보일 수 있지만 [[멀티플렉싱(Multiplexing)]]에서 필요한 개념이 이것이다. 
	❗️직접적으로 select 시스템콜이 async 방식이라는 이야기는 아니다.
### 성능 문제
Blocking은 OS 관점에서 스레드가 자신의 제어권을 반납하고 Blocked 상태로 전환된 것이다. 주된 이유는 당장 획득할 수 없는 자원을 요청하기 때문이다. 
I/O 작업의 경우, 디스크를 읽거나 네트워크 패킷을 대기하는 등 CPU의 속도에 비해 한참 느린 작업이다.
스레드들이 이렇게 Blocking되기 시작하면 CPU 사용률이 떨어지게 된다.
이후 발생할 수 있는 문제들이 다음과 같다.
- 스레드 폭발: 원래 스레드가 멈췄기 때문에 비동기 작업을 위해 새로운 스레드를 생성한다. 그리고 이 스레드 또한 I/O 대기를 시작할 경우 상황이 반복되어 스레드 개수가 급격히 증가한다.
- Context Switching 오버헤드: 스레드가 Blocked되고, 깨어날 때마다 Context Switching 비용이 발생하는데, 스레드 폭발 문제가 일어난 경우 더 크게 발생한다.
- 메인 스레드 블로킹: UI 업데이트를 담당하는 메인 스레드에서 블로킹이 발생할 경우 화면이 버벅이는 것으로 보여 큰 성능 문제를 야기한다. 
### I/O 과정
- I/O 요청이 필요할 경우, 커널 모드로 진입하여 OS에 요청한다.
- OS는 해당 스레드의 상태를 Waiting Queue에 넣는다.
- Context Switching 발생.
- I/O 작업이 장치에서 완료되면, 인터럽트를 발생시킨다.
- ISR(Interrupt Service Routine): 장치의 데이터를 커널 메모리로 옮긴다.
- Waiting Queue에 있던 스레드가 Ready Queue로 들어간다. 
## 2. 탐구 내용 (실무 / iOS 연결)
### IBM blocking/sync
위 2 * 2 blocking/sync 관계에서 sync+blocking, async+non-blocking은 어쩌면 가장 일반적인 내용이다. 동기 작업이란 위 관점에 단순히 callee가 caller의 시간에 맞추어 답변을 제공한다고 볼 수 있지만, 실제로는 caller가 blocking되는 상황이 가장 흔하며, 대기하다가 동기적으로 결과를 회수하는 것까지가 동기 작업으로 보인다. 비동기 작업 역시 마찬가지로, callee가 caller에 상관 없이 결과를 제공하는 것이지만, 실제로 기대하는 바는 caller가 호출 이후에 자신의 작업을 계속 수행하는 것을 기대한다. 
#### 관점 설정
서술 중 이해 과정에서 사용된 예시 때문에, 또는 용어마다 더 널리 사용되는 분야가 따로 있기 때문에 다른 설명이 섞일 수 있으나 기본적으로는 아래의 관점에서 보는 것이 IBM의 설명이다.
- Application과 Kernel의 관계.
- I/O 과정을 설명.
- Application이 Caller, Kernel이 Callee
#### Synchronous blocking I/O
read, write과 같은 시스템 호출. 
유저가 read를 호출했다 하면 커널은 데이터가 사용자 버퍼에 복사되기 전까지 리턴하지 않고 유저 프로세스는 작업을 중단한 채 대기한다.
클라이언트가 여러 개인 서버의 경우, 클라이언트가 I/O에 들어가면 다른 클라이언트가 작업을 못하게 되므로, 프로세스나 스레드를 여러 개 두어야 한다. 다만 클라이언트 수만큼 스레드가 증가할 우려가 있따.
#### Polling
그렇다면 다른 조합은 어떨까?
sync-nonblocking의 조합, 즉 폴링 방식은 callee의 결과를 caller가 지속적으로 확인하며 결과를 수집하려는 형태이다. 왜 그래야할까?
HTTP 네트워크의 방식은 단방향 통식이다. 클라이언트가 서버에 요청을 보내면 서버가 응답을 보내는 방식이다. 그런데 서버가 먼저 선제적으로 데이터를 업데이트해야되는 상황이라면? 클라이언트에서 서버가 정보를 업데이트했는지 꾸준히 확인하는 방식 뿐이다. 이것에 Polling이다. 
위 상황에서 클라이언트는 non-blocking 방식으로 자신의 작업을 한다. HTTP의 단방향 방식은 동기적으로만 정보를 전달한다.
OS 커널 레벨에서도 non-blocking 소켓에 대해 메시지가 도착할 때까지 read() 시스템 콜을 던져 CPU를 소모하는 방식이다.
#### Asynchronous blocking I/O
연관: [[멀티플렉싱(Multiplexing)]]
IBM에서는 Asynchronous blocking을 설명하며 select 시스템콜을 예로 들었다.
```
In this model, non-blocking I/O is configured, and then the blocking `select` system call is used to determine when there's any activity for an I/O descriptor.
```
그러니까 I/O가 non-blocking으로 동작하고, 이를 blocking system call인 select가 I/O descriptor에서 활동을 읽어온다는 것이다.
헷갈리는 부분은 위에서 설정한 관점에서 어긋난다는 것이다. 어플리케이션을 caller, 커널을 callee로 생각한다면 select가 결국에는 blocking에 sync로 동작하기 때문에 그렇게 이해하는 것이 맞게 보인다. 
IBM이 말하고자 하는 것은 I/O가 마무리되기 전까지 어플리케이션이 작동할 것은 없기 때문에 blocking으로 보고, 다만 I/O descriptor 쪽에서는 non-blocking으로 작동하며 변화를 descriptor에 기록하기 때문에 일련의 과정을 async로 보는 것 같다.
#### 멀티플렉싱 관련 정리
- 멀티플렉싱이란
	어플리케이션이 수많은 소켓을 통제하기 위해서 소켓 수만큼의 스레드를 만들거나, 소켓을 전부 순회함으로 인해 생기는 메모리나 CPU의 문제를 해결하기 위해 생긴 방식.
	데이터가 언제 올지 모르기 때문에 인터럽트를 통해 해결.
- Blocking? Non-blocking?
	- 대기하는 어플리케이션 입장에서는 blocking. blocked상태에 들어가 CPU 사용률을 방어한다.
	- 데이터가 와 커널이 스레드를 깨웠을 때, 소켓은 non-blocking으로 설정되어 오류가 있거나 데이터가 사라졌더라도 blocking되지 않는다.
- sync? async?
	- POSIX/학문적 관점: 커널이 이벤트를 보내 깨운다 하더라도, Application 스레드가 read()를 호출해서 동기적으로 읽기 때문에 sync로 본다.
	- IBM/아키텍쳐 관점: 네트워크에서 패킷이 도착해 수신 버퍼를 채우는 행위 자체는 Application의 흐름과 무관하게 비동기적으로 발생하는 것이다. Application은 단지 Event Notification을 받을 뿐이다.
### iOS
#### Data(contentsOf: URL)의 blocking
NSData의 initializer 중 contentsOf로 URL를 받는 것을 보면 다음과 같은 안내문이 써있다.
```
Important

As this method runs synchronously and blocks the calling thread until it finishes, don’t invoke it from the main thread. Use file coordination or one of the nonblocking file-related APIs instead. For more information, see [Improving performance and stability when accessing the file system](doc://com.apple.documentation/documentation/foundation/improving-performance-and-stability-when-accessing-the-file-system).
```
Blocking-sync 방식이기 때문에 메인 스레드에서 호출하지 말라는 것이다. Data(contentsOf)가 네트워크에서 결과를 받아올 때까지 메인 스레드가 block되면 화면이 멈추기 때문이다. 
❗️메인 스레드에서 호출하는 것이 문제가 된다면? DispatchQueue.global().async를 사용하여 비동기 작업으로 보낸다면?
	메인 스레드가 block되는 최악의 상황은 막을 수 있지만 GCD는 비동기 I/O 작업에 대해 Thread Explosion이라는 알려진 문제가 있기 때문에 완벽한 해답이 되지 못한다.
결론: Data(contentsOf: URL)을 네트워크 다운로드 용도로 사용하지 말아라.
#### URLSession.shared.dataTask
위 Data(contentsOf)의 대안으로 제시되는 방법이다.
URLSession은 내부적으로 각 앱의 프로세스가 아니라, iOS 데몬이나 하위 커널 스택에 I/O작업을 위임한다. 이 때 kqueue라는 I/O 멀티플렉싱 기술을 사용한다.
멀티플렉싱을 사용하기 때문에 스레드를 블로킹시키지 않고, 패킷이 도착하여 인터럽트가 발생하면 그 때 Completion Handler를 호출한다.
## 3. 의문 / 논점 

## 4. 참고 자료
- https://developer.ibm.com/articles/l-async/
