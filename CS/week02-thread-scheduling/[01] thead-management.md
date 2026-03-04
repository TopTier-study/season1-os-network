# 스레드 관리 (라이브러리, 스레드 풀)

### 학습 키워드

- 스레드 라이브러리
- Pthreads, Synchronous Threading, Asynchronous Threading
- Thread pool
- GCD

## 1. 핵심 개념

### 스레드 라이브러리 개념과 종류

**스레드 라이브러리**

스레드를 생성하고 관리할 수 있는 API를 제공

**User space vs Kernel space**

- 스레드 라이브러리는 주로 두 가지 방식 중 하나로 구현됨
- User space
    - 라이브러리를 위한 모든 코드와 자료구조가 유저 공간에 존재해 커널의 지원이 필요없음.
    유저 공간 내의 로컬 함수 호출로 처리하는 것
- Kernel space
    - 코드나 데이터 구조가 커널 공간에 존재해서 라이브러리 API 호출시 시스템 콜 호출을 통해 os에서 직접적으로 지원하는 커널 수준 라이브러리

**종류**

**Pthreads**

- user, kernel-level 모두 지원
- POSIX 표준의 확장
- Linux, Unix, macOS에서 사용

**Windows **

- Windows 시스템에서 사용하는 kernel-level 라이브러리

**Java threads**

- 자바 프로그램 내에서 생성되고 관리되도록
- JVM이 host os 위에서 돌아가므로, Java threads API도 host os 위에서 돌아가도록 구현됨
→ Windows API 사용
- 전역 변수 개념이 없으므로, 공유 데이터에 대한 접근은 스레드 간에 명시적으로 배치해야 함.

**멀티스레드 생성 전략**

**Synchronous threading**

- 부모 스레드가 자식 스레드를 여러 개 생성하고, 모든 자식 스레드가 작업을 끝낼때까지 wait하다가
종료하면 재개하는 방식
- 해당 방식은 스레드 간 데이터 공유가 중요할 때 사용

**Asynchronous threading**

- 부모가 자식 스레드를 생성하고, 자신의 작업을 재개해서 부모와 자식이 독립적으로 동시 작업이 가능한 방식
- 스레드 간 독립성이 중요

---

### Implicit Threading

- 스레드 수가 점점 늘어나면서, 프로그램 개발자가 관리하기 힘들어졌음
→ 이를 개발자 대신 컴파일러/런타임 라이브러리에 맡기는 방법은 없을까?
→ Implicit threading을 통해 해결
- **Implicit threading**
    - 스레드 생성과 관리의 책임을 프로그래머 대신 컴파일러나 런타임 라이브러리에서 담당하는 것
    - 암묵적 스레딩을 사용하려면?
        - 개발자는 Task만 알고 던져주면 됨. 이는 작업의 단위로 병렬 실행이 가능해야 함
        - 스레드는 운영체제의 자원이라 만들고 지우는 데 비용이 많이 듦. 반면 **태스크**는 단순한 '코드 조각'이나 '객체'에 불과해서 수만 개를 만들어도 가벼움.
        - 개발자가 Task를 던지면, 시스템은 알아서 해당 작업들을 별개의 스레드에 할당함

---

### Thread Pools

- 기존 멀티스레드 환경의 문제점
    - 한 번 사용된 스레드가 버려지는 것을 고려할 때 스레드의 생성 비용이 낭비스러움
    - 시스템에서 동시에 활성될 수 있는 스레드 최대 수 제한이 없어 시스템 자원이 낭비될 수 있음
- Thread pool
    - **구동 시점에 몇 개의 스레드를 생성해놓고, 작업을 기다리고 있는 형태**
    - 동작 원리
        - 처리 요청이 들어오면 새 스레드를 생성하지 않고, 스레드 풀에 요청을 보냄
        - 스레드 풀에서 이용 가능한 스레드가 있다면, 스레드가 깨어나고 해당 요청은 즉시 처리됨
        - 만약 이용 가능한 스레드가 없다면, 작업은 큐에 들어가서 스레드가 생길 때까지 대기
        - 요청 처리가 종료되면 다시 스레드 풀로 돌아가서 다른 요청을 기다림
    - 최대 스레드 수
        - 주로 시스템 자원량에 따라 달라지지만, 정교한 설계에서는 사용 패턴에 따라 동적으로 그 수를 조정함 (GCD)

## 2. 탐구 내용 (실무 / iOS 연결)

### GCD(Grand Central Dispatch)

- Apple에서 개발, iOS 및 macOS의 스레드 풀
- 런타임 라이브러리 + APIs + Language extension의 조합
- `libdispatch` 라이브러리로 구현

**Dispatch queue**

- 런타임에 tasks들을 해당 큐에 삽입
- 큐에서 빼서, 이용 가능한 스레드에 할당
- Serial queue
    - 선입선출, 순차실행
    - 각 프로세스들은 각자의 serial queue를 가짐 (main queue)
- Custom queue
    - 개발자에 의해 특정 프로세스에 대한 별도의 직렬 큐를 사용할 수도 있음 (private dispatch queue)
    - 기본 직렬, 병렬로 지정도 가능
- Concurrent queue
    - 선입선출, 여러 개의 tasks가 큐에서 빠져 병렬로 처리될 수 있음
    - 이는 system-wide한 concurrent queue를 사용하는 것 (Global dispatch queues)
        - 운영체제 전체의 스레드 풀을 공유함
    - 4개의 QoS에 따라 나뉨

**QoS (Quality of Service) Classes**

- User-interactive
    - UI 업데이트와 같이 빠른 반응성이 중요한 이벤트의 경우에 해당
    - 무거운 작업 금지
- User-initiated
    - User-interactive와 비슷하게 사용자 행동과 관련된 클래스지만 처리 시간이 좀 더 걸림. 그렇지만 빨리 처리될 필요는 없음
- Utility
    - 더 긴 처리 시간이 걸리지만 빨리 처리될 필요 없음
- Background
    - 유저에게 보이지 않으면서 시간도 크게 중요하지 않음

**GCD에서 사용한 Language extension**

- C계열 언어에 존재하지 않는 블록 문법을 `^` 기호를 사용해 **Blocks**라는 이름으로 추가
- Swift는 클로저 사용
- 블록 내부가 곧 수행될 작업의 단위

## 3. 의문 / 논점

## 4. 참고 자료
