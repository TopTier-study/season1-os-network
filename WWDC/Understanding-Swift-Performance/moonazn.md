## 1. 시청한 WWDC 영상
[Understanding Swift Performance - WWDC16 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2016/416/)

## 2. 내용 요약

성능 문제는 CPU 연산 문제보다 **메모리 접근 비용**이 더 큰 영향을 미치는 경우가 많다.

#### 속도 차이
* CPU register 접근: 매우 빠름
* L1 cache: 빠름
* L2 / L3 cache: 점점 느려짐
* RAM 접근: 매우 느림

> 즉 프로그램이 느려지는 주요 이유는 ‘데이터를 많이 계산해서’ 보다 **‘데이터가 메모리에 흩어져 있어서 캐시 미스가 발생하기 때문’**이다.

따라서 Swift의 추상화 매커니즘이 성능에 미치는 영향을 이해하기 위해서는 기본 구현을 이해하는 것이 효과적이다.

### Allocation: 내 인스턴스가 Stack과 Heap 중 어디에 할당되는지
Swift는 자동으로 메모리를 할당 & 해제함.

#### Stack
- LIFO 구조
  - Top(스택 포인터 위치)에서만 Push/Pop 가능
- 함수 호출 시 스택 포인터가 가리키고 있는 곳 **줄이기** = ‘필요한 메모리 할당’ (Decrement stack pointer to allocate)
- 함수 종료 시 스택 포인터를 줄이기 이전 위치로 **증가시키기** = ‘메모리 할당 해제’ (Increment stack pointer to deallocate)

#### Heap
- Stack보다 더 동적이지만 성능이 비교적 떨어짐.
- 메모리 할당을 위해서 힙 내에 사용되지 않는 적절한 크기의 블록을 검색 (Search for unused block of memory to allocate)
- 메모리 할당 해제를 위해서 해당 메모리를 적절한 위치로 다시 삽입 (Reinsert block of memory to deallocate)
- 여러 스레드가 동시에 힙에 메모리를 할당할 수 있음 -> **lock 또는 기타 동기화 매커니즘을 통해 무결성을 보장해야 함.** (가장 큰 비용!)

### Reference Counting: 내가 인스턴스를 전달할 때 얼마나 많은 레퍼런스 카운팅 오버헤드가 일어나는지

레퍼런스 카운팅 작업은 실제로 빈번하게 수행된다. (이 빈도에 의해 카운팅 비용이 증가할 수 있음.)
힙 할당과 마찬가지로 레퍼런스가 여러 스레드에 의해 동시에 추가 / 제거될 수 있기 때문에 **스레드 안전성을 고려해야 한다**. (atomically하게 레퍼런스 카운드가 증가 / 감소되어야 함.)

- retain: 레퍼런스 카운트 += 1
- release: 레퍼런스 카운트 -= 1
- Swift의 기본 타입은 대부분 struct이지만, **String의 경우 contents를 힙에 저장 -> 힙 할당 발생** ( = 레퍼런스 카운트 계산 필요)
  - **UIFont**는 class
  - **Label**은 struct
  - **URL**는 struct이지만 init할 때 String을 받으므로 **힙 할당 발생**
  - **UUID**는 128bit 식별자를 struct에 직접 저장하므로 **힙 할당 X** + 고유 식별자로 안전
    - `UUID: A universally unique value that can be used to identify types, interfaces, and other items`
- **struct 내부에 레퍼런스가 있는 경우 레퍼런스 수에 비례하여 레퍼런스 카운팅 오버헤드 비용 발생**
  - **둘 이상의 레퍼런스가 존재하는 경우 class보다 레퍼런스 카운팅 오버헤드가 더 커짐.**

-> enum, UUID 등을 활용하여 힙 할당을 줄일 수 있음. ( = 레퍼런스 카운팅 비용 감소 = 성능 개선)

### Method Dispatch: 내가 내 인스턴스의 메서드를 호출할 때 static dispatch와 dynamic dispatch 중 어떤 방식을 통해 호출되는지

#### static dispatch
: **컴파일 타임**에 결정 (컴파일러가 실제로 어떤 구현이 실행되는지 알 수 있는 상황)

- inline과 같은 컴파일러 최적화가 가능해짐.

#### dynamic dispatch
: 컴파일 타임에 어떤 구현을 실행해야 하는지 결정되지 X, **런타임**에 실제 구현으로 jump

- 컴파일러의 가시성을 차단하므로 최적화가 막힘.
- **다형성**을 위해 사용됨.
- 다형성으로 구현된 타입의 메서드를 호출 시 실제 호출되어야 하는 구현을 컴파일러가 찾는 방법 (class 상속)
  1. 컴파일러는 해당 클래스 타입의 정보를 정적 메모리에 저장
  2. 실제로 함수 호출 시 컴파일러가 타입 및 정적 메모리의 vtable 조회
  3. 실행하기에 적합한 구현 메서드 찾음.
  4. 파라미터로 실제 인스턴스 전달
- class는 기본적으로 **dynamic dispatch** (메서드 체인, 인라인과 같은 최적화 막음)
  - class를 서브클래싱하지 않는 경우 **final**로 명시 -> 컴파일러가 **static dispatch**를 함.
  - private / fileprivate 등 **컴파일러가 앱 내에서 서브클래싱하지 않을 것이라는 것을 추론 & 입증할 수 있는 경우**에도 **static dispatch**

-> 비용: dynamic > static
---
### Protocol
- class 상속이 아닌 `프로토콜 채택 + struct`로 구현되어 있을 때 컴파일러가 올바른 메서드 dispatch를 하는 방법: table 기반 매커니즘인 **Protocol Witness Table**
  - PWT의 엔트리와 해당 타입의 구현이 연결되어 있기 때문에 메서드 구현을 찾을 수 있음.
  - **Swift는 existential Container의 필드에서 pwt를 조회하고, 해당 테이블의 fixed offset에 있는 메서드를 조회하여 구현으로 이동한다.**

#### Existential Container?
: inline valueBuffer(공간 3개) + value witness table의 레퍼런스 + protocol witness table의 레퍼런스

- 첫 부분 3개는 valueBuffer용으로 예약되어 있음.
  - 저장될 값 크기에 따라 다른 방식으로 저장
    - 값이 3 word 이하 크기이면 (ex: struct 프로퍼티 2개) -> 바로 저장 (inline valueBuffer)
    - 값이 3 word보다 크면 (ex: 프로퍼티 4개 이상인 큰 타입) -> 힙에 메모리 할당 후 포인터를 저장
  - 저장 방식 차이 관리: **Value Witness Table**
    - 값의 lifetime을 관리
    - 타입마다 Value Witness Table 존재
    - 4개의 엔트리
      - **allocate**: inline valueBuffer가 불가능한 경우 힙에 메모리 할당
      - **copy**: 실제로 값 할당 (stack inline / 힙에 값 할당)
      - **destruct**: 로컬 변수 lifetime 종료 시 호출되며 값에 대한 레퍼런스 카운트 감소시킴. (힙에 메모리가 할당된 경우)
      - **deallocate**: 종료 후 힙 할당 해제 및 스택 메모리 해제(= 스택 포인터 값을 증가시킴)
- 프로토콜 타입의 로컬 변수 lifetime이 시작될 때
  1. Swift가 Value Witness Table 내부의 allocate 함수 호출
  2. 로컬 변수를 초기화하는 assignment 소스에서 Existential Container로 값 복사
- 로컬 변수 lifetime 종료 시
  1. Swift가 Value Witness Table에서 destruct 엔트리 호출
  2. 종료 후 deallocate 함수 호출
  3. 큰 타입의 경우 힙에 할당한 메모리 해제
- 하나의 호출 컨텍스트 당 하나의 타입만 존재할 경우 existential container 사용 X ( = 무조건 만드는 것이 아님), vwt & pwt만 개별적으로 사용

> **정리**
> Existential Container: value witness table, protocol witness table에 대한 레퍼런스 저장
> - value witness table: 저장 프로퍼티 관리
> - protocol witness table: 프로토콜 메서드 관리
> - 두 테이블은 런타임 메타데이터 영역에 존재하며 타입마다 하나씩 존재한다.

#### COW (copy and write)
1. class에서 동일한 값을 복사한 레퍼런스를 만들 경우 참조를 공유
2. 이후 새로운 레퍼런스의 값을 수정 시 레퍼런스 카운트 확인
   - **레퍼런스 카운팅이 1보다 큰 경우 기존 레퍼런스의 복사본 생성 후 해당 복사본 변경**
---
### Generic

- static한 형태의 다형성(polymorphism) 지원
  - ’static한 형태’ = ‘타입 T가 실제 구체 타입으로 대체된다’
  - -> specialization 컴파일러 최적화 가능
    ```swift
    func drawACopyOfAPoint(local: Point) { local.draw() }
    func drawACopyOfALine(local: Line) { local.draw() }
    
    // 최적화 전
    let local = Point()
    local.draw()
    drawACopyOfALine(Line(...))
    
    // 최적화 후
    Point().draw()
    Line().draw()
    ```
- 이 경우 existential container를 사용하지 않는 경우에 해당

## 3. 준비한 질문
### 3-1) 왜 Swift는 Value Type 중심 언어 설계를 했을까?

### 질문
Swift는 struct 같은 **Value Type 사용을 권장**한다.
왜 성능 측면에서 Value Type이 Reference Type보다 유리할 수 있을까?

### 답변
1. **Stack allocation 가능**
Value Type은 스택에 저장될 수 있어 **힙 할당 비용을 아낄 수 있다.**

> Value Type이 힙에 올라갈 수 있는 경우
> - 클로저 캡처
> - existential container
> - large struct
> - generic abstraction
> - escaping context
> -> Value Type은 힙 할당이 반드시 필요하지 않음.

힙에 할당하면 다음 비용이 발생한다.
* malloc/free 호출
* 메모리 동기화
* fragmentation 관리

스택은 단순한 pointer 이동으로 메모리를 관리한다.
```
push → stack pointer 증가
pop → stack pointer 감소
```
따라서 할당 비용이 매우 낮다.

2. **ARC 비용이 없다**
Reference Type(class)은 ARC를 사용한다.

ARC는 retain, release, reference counting 작업을 수행한다.
이 과정에서 **메모리 접근과 동기화 비용**이 발생할 수 있다.
(멀티스레드 환경에서는 **atomic reference counting**이 필요할 수 있어 추가적인 비용이 발생한다.)

Value Type은 reference counting이 필요 없기 때문에 이 비용이 없다.

3. **데이터 locality**
Value Type은 데이터가 **연속된 메모리**에 저장되는 경우가 많다.

#### 예시
- `Array<struct>` -> 이 경우 CPU 캐시 히트 비율이 높아진다.
- `Array<class>` -> 객체가 heap에 흩어져 있어 **cache miss가 증가**할 수 있다.

### 3-2) Protocol을 사용할 때 existential vs generic의 성능 차이는 왜 발생할까?

### 질문
Protocol을 사용할 때 protocol type (existential)과 generic 방식은 모두 다형성을 제공한다.
그런데 왜 generic 방식이 성능적으로 더 유리할 수 있을까?

### 답변
1. **Existential은 런타임 타입 확인이 필요하다**
Protocol 타입으로 값을 저장하면 Swift는 **existential container**를 사용한다.
existential container에는 다음 정보가 포함된다.
* 실제 값
* Value Witness Table
* Protocol Witness Table

메서드를 호출할 때 Swift는
1. protocol witness table 조회
2. 해당 메서드의 구현 찾기
3. 실제 함수로 jump
-> 이 과정이 **runtime dispatch**를 발생시킨다.

2. **Generic은 compile-time specialization이 가능하다**
Generic은 컴파일 시점에 실제 타입으로 치환된다.

3. **static dispatch가 가능해진다**
Generic specialization이 일어나면 다음과 같은 최적화가 가능하다.

* 메서드 호출 **static dispatch**
* inline 최적화 가능
* witness table lookup 제거

4. **Existential container 비용이 없다**
Generic에서는 다음과 같은 비용이 발생하지 않는다.

* existential container 생성
* value witness table 호출
* protocol witness table lookup

> **정리**
> - existential: **runtime polymorphism** 
> - generic: **compile-time polymorphism** 
> -> 따라서 generic이 **더 강한 컴파일러 최적화가 가능하다.**
