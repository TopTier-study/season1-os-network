## 1. 시청한 WWDC 영상
- 세션 제목: Understanding Swift Performance
- 링크: https://developer.apple.com/videos/play/wwdc2016/416/
	참고한 요약 글: https://zeddios.tistory.com/596
## 2. 내용 요약
### 주요 관점 소개
Swift의 성능을 3가지 관점에서 소개한다.
- Stack에 할당 vs Heap에 할당
- Reference Counting 횟수
- Static Dispatch vs Dynamic Dispatch
Stack, 적은 Reference Counting, 정적 디스패치가 성능에 유리하다.
### Allocation: Stack vs Heap
- Stack
	자료 구조의 특징 상 push와 pop의 속도가 매우 빠르다.
	Stack은 한쪽 방향으로만 입출력이 일어나며, 이 주소를 Stack Pointer가 유지한다. 주소 하나에 의해 입출력이 일어나기 때문에 오버헤드가 적다.
- Heap
	Heap에 할당하기 위해서는 비어있는 메모리 공간을 탐색해야되기 때문에 비교적 복잡하다.
	할당을 해제할 때도 해당 메모리를 Reinsert하는 과정이 비싸다.
	- Reinsert: 기존에 관리하던 사용 가능한 메모리 공간에 새롭게 병합하는 행위.
	Heap 할당에 대한 Thread Safety 문제 때문에 Heap에 할당을 할 때는 lock이 동작한다.
#### struct vs class
- struct
	stack에 저장되며, 가진 프로퍼티 크기만큼 공간을 차지한다.
- class
	Heap에 class를 할당하는 과정에서 class가 가진 프로퍼티 외에도 다음이 저장되어야 한다.
	- Type Metadata Pointer(isa 포인터, 8바이트): 객체 타입을 식별하게 해주는 포인터
	- Reference Count(8바이트)
	또한 stack에 이 class를 가리킬 포인터 변수가 저장될 것이다.
#### String
String은 값 타입이지만 heap에 character 타입으로 문자들을 간접적으로 저장되기 때문에 String의 사용이 heap allocation을 유발할 수 있다. 딕셔너리의 key 값으로 String을 사용하는 경우에도 Heap 영역을 사용하게 된다.
- 참고
	Small String Optimization: String 구조체는 스택에서 8바이트의 Heap에서 문자열이 저장된 주소와 문자열의 길이, 남은 공간 등 플래그 정보로 이루어진다.
	하지만 문자열이 16바이트 미만일 경우 이 공간을 문자열을 저장하는데 사용하면 되기 때문에 SSO 최적화를 진행하여 스택에만 String을 저장한다.
### Reference Counting
- 오버헤드
	- +1, -1 연산 이상의 작업
	- Thread safety를 고려
- retain: reference count를 +1 하는 연산.
#### Struct 내부에 reference type이 있는 경우
reference type을 가진 struct 변수를 복사할 때 reference를 복사하는 과정에서 arc 비용을 지불하게 됨. 
하나의 reference에 대해 지불하는 arc 비용 == class를 복사하는데 지불하는 arc 비용이기 때문에 둘 이상일 경우 class보다 많은 arc 비용을 지불하게 된다.
❗️위에서 언급한 이유로, 가장 조심해야 할 유형이 String인데, UUID로 대체하면 좋다.
### Method Dispatch
#### Static Dispatch
컴파일러가 실행될 함수의 위치를 예측할 수 있다면 Inlining 최적화를 통해 함수 호출 비용을 줄일 수 있다.
#### Dynamic Dispatch
다형성을 구현하기 위한 방법.
컴파일러는 class 타입 정보에 대한 것을 정적 메모리에 저장한다. 실제 함수가 호출되면, virtual method table을 확인하여 실제 인스턴스의 함수를 호출한다. 
❗️class의 다형성 특징을 사용하지 않을 경우 성능적으로는 Static Dispatch가 우수하기 때문에 final을 붙여주면 Static Dispatch를 할 수 있다. 
## 3. 준비한 질문

## 4. 토론 / 공유 내용 정리

## 5. 의문 / 추가 탐구 포인트
