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
### Existential Container
구조체 인스턴스가 프로토콜 타입의 변수에 담길 때 생성되는 컨테이너.
5칸(40바이트, 64비트 기준)
- Value Buffer(3칸, 24바이트): 실제 구조체의 데이터(저장 프로퍼티)
- Value Witness Table(1칸, 8바이트)
- Protocol Witness Table(1칸 8바이트)
3words 이상의 값은 heap에 할당되고, 포인터만 value buffer에 할당.
#### Value Witness Table
동적 관리를 위해 구조체를 다루는 방법에 대한 정보를 담음.
구조체의 생명주기를 다루는 C++ 런타임 함수의 포인터가 담김.
- allocate
- copy
- destruct
- deallocate
#### Protocol Witness Table
구조체가 프로토콜을 채택한 경우의 동작을 위해 프로토콜이 요구하는 메소드가 실제 구조체 메모리의 어디에 구현되어 있는지 매핑한 테이블.
동적 디스패치이기 때문에 V-Table(virtual method table) 수준으로 느려짐.
### Copy-on-Write 적용
위에서 구조체-프로토콜의 조합에서 저장 프로퍼티 크기가 24바이트를 넘으면 Existential Container에 저장되는 것이 아니라 heap으로 넘어감을 확인했다. 이를 예방하기 위해 권장되는 방법은 class 내에 프로퍼티를 묶어 저장하는 방식이다.
이러한 방식으로 저장하면 복사할 때 참조만 복사하게 된다.
참조만 복사하면 상태 공유의 우려가 생기는데, 이는 Mutating 과정에서 isKnownUniquelyReferenced 함수를 호출하여 다른 참조가 존재할 경우 깊은 복사를 수행한다.

String, Array, Dictionary, Set은 이미 Copy-on-Write가 적용되어있지만 커스텀 Struct는 직접 구현해야 한다.
```Swift
// 1. 힙에 올라갈 무거운 데이터용 클래스
class HeavyStorage {
    var data: [Int] = [1, 2, 3, 4, 5]
    
    // 깊은 복사를 위한 메서드 직접 구현
    func copy() -> HeavyStorage {
        let newStorage = HeavyStorage()
        newStorage.data = self.data
        return newStorage
    }
}

// 2. 개발자가 직접 COW를 적용한 구조체
struct MyCOWStruct {
    private var storage = HeavyStorage()
    
    // 3. 데이터를 읽고 쓸 때 프로퍼티 옵저버(get/set)를 통해 검문소 설치!
    var data: [Int] {
        get { 
            return storage.data // 읽을 땐 그냥 공유 (빠름!)
        }
        set {
            // ✨ 여기가 핵심! 수정(Write)하려 할 때 참조 상태를 묻는다.
            // "나 말고 이 storage 쳐다보는 놈 있어?"
            if !isKnownUniquelyReferenced(&storage) {
                print("🚨 다중 참조 발견! 나만의 복사본을 새로 만듭니다(Deep Copy).")
                storage = storage.copy()
            }
            // 이제 안전하게 내 소유가 된 힙 메모리를 수정
            storage.data = newValue
        }
    }
}
```
### Generic Specialization
제네릭을 사용할 경우 매개변수에서 해당 타입을 대체하고 해당 타입 버전의 함수를 만든다. 구조체 point, line이 protocol drawable을 구현하고, 제네릭 타입으로 인자를 받으면 point인 버전, line인 버전의 함수를 만든다.
### Aggressive Compiler Optimization
- 인라이닝: 함수 코드를 복사하는 방식.
- Devirtualization: 실제 상속이 없을 경우 V-Table을 사용하지 않음.(동적 디스패치->정적 디스패치)
- Generic Specialization
#### Whole Module Optimization(WMO)
기본적인 컴파일 방식은 모듈별로 컴파일하는 것이지만, 이런 경우 Generic Specialization 같은 최적화가 코드가 다른 파일에 있으면 안 된다. 따라서 WMO를 켜주어야 함.
## 3. 준비한 질문
- struct를 복사할 때 class를 복사할 때보다 더 높은 비용을 지불하는 경우와 그 이유는?
	- struct 내부에 참조 타입이 둘 이상 있으면 복사하는 과정에서 참조 타입을 heap 영역에서 arc관리를 해야하고, 이것이 타입 각각에 대해 이루어지기 때문에 arc비용 관점에서 높은 비용을 지불하게 된다. 
- String을 프로퍼티로 갖는 struct는 어떤 문제를 야기할까?
	- String은 15바이트까지는 값 타입으로 stack 영역에 할당되지만, 그 이상부터는 문자들이 heap 영역에 할당되기 때문에 heap 연산이 포함되어 struct를 복사할 때 내부에 참조 타입이 있을 때와 같은 문제를 야기하게 된다. 
- Heap을 사용했을 때 Stack보다 상대적으로 비용이 큰 부분? (두 가지 이상)
	- 빈 heap 공간 탐색 비용
	- heap arc 관리 및 이로인한 thread safety 관리
	- 메모리 Reinsert
- stack과 heap의 성능 비교를 동시성 관점에서 설명하기.
	- arc를 관리하는 행위는 동시성 문제가 야기될 수 있어 thread safety하게 관리되고, 성능 오버헤드가 된다.
