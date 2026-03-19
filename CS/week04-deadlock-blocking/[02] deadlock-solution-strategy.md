# Deadlock 해결 전략
### 학습 키워드
- deadlock
- prevention
- avoidance
- detection
- recovery
- gcd

## 1. 핵심 개념

### Deadlock
: 여러 스레드 또는 프로세스가 서로가 가진 자원을 기다리며 **영원히 진행하지 못하는 상태**

#### 발생 조건
다음 조건들이 동시에 만족될 때 deadlock이 발생할 수 있다.

1. **Mutual Exclusion**
   - 하나의 자원을 한 번에 하나의 프로세스만 사용할 수 있음.
2. **Hold and Wait**
   - 프로세스가 이미 자원을 가진 상태에서 다른 자원을 기다림.
3. **No Preemption**
   - 자원을 강제로 빼앗을 수 없음.
4. **Circular Wait**
   - 프로세스들이 원형 구조로 서로의 자원을 기다림.

#### 해결 전략 (feat. 운영체제)
1. Prevention
   - Deadlock 조건 자체를 제거
2. Avoidance
   - Deadlock이 발생할 가능성이 있는 상태를 회피
3. Detection
   - Deadlock 발생을 허용하고 이후 탐지
4. Recovery
   - Deadlock 발견 후 시스템을 복구

## 2. 탐구 내용 (실무 / iOS 연결)
### 1) Prevention (예방)
: Deadlock 발생 조건 중 하나를 제거하는 방식

#### a. Mutual Exclusion 조건 방지
- 한 번에 여러 프로세스가 공유 자원을 사용할 수 있게 한다. ( = **모든 자원을 공유 가능하게 만든다.**)
- 이론적으로 데드락을 차단시키지만, **현실적으로** 모든 자원을 공유하는 것은 **무리**이다.

#### b. Hold and Wait 조건 방지
- 프로세스 실행에 필요한 **모든 자원을 한꺼번에 요구하고** **허용할 때까지 작업 보류** -> 이후 다른 자원을 점유하기 위한 **대기를 없앤다.**
  - 특정 프로세스에 자원을 모두 할당 or 아예 할당 X 방식
- 단 한 프로세스에 필요한 자원을 몰아주는 방식으로 동작하기 때문에 **자원의 활용률이 낮아질 우려**가 있다.
- **많은 자원을 사용해야 하는 프로세스의 경우** 적게 사용하는 프로세스에 비해 **자원을 사용할 타이밍을 확보하기 힘들어짐** -> **기아현상 우려**

#### c. No Preemption 조건 방지
- 높은 우선순위의 프로세스가 자원을 **선점할 수 있도록** 한다.
- 선점할 수 있는 자원(예: CPU)에 대해서는 효과적인 방법
- **모든 자원을 선점할 수 있는 것은 아니기 때문에 범용성이 떨어진다.**
  - 예) 프린터가 한 프로세스에 대해서 사용되고 있는데 다른 프로세스가 이를 빼앗아 프린터를 갑자기 사용할 수는 없다.

#### d. Circular Wait 조건 방지
- 모든 자원에 번호를 붙이고 오름차순으로 자원 할당 -> **한 방향으로만 자원을 요구**할 수 있도록 한다.
- 시스템 내의 수많은 자원에 **모두 번호를 붙이는 것이 어렵고**, **특정 자원에 대해 활용률이 떨어질 수 있다.**

#### 예시 1
```
// Thread A
lock A → lock B

// Thread B
lock B → lock A
```
-> 이 구조에서는 **Circular Wait**가 발생할 수 있음.

#### 예시 2: 항상 같은 순서로 lock을 획득하도록 규칙을 정한다.

```
// 규칙: 항상 A → B 순서로 lock

// Thread A
lock A → lock B

// Thread B
lock A → lock B
```
-> 이와 같이 **순서를 고정하면 Deadlock이 발생하지 않음.**
(실무에서 가장 많이 사용하는 방식)

### 2) Avoidance (회피)
: Deadlock이 발생할 가능성이 있는 상태를 **미리 계산하여 회피하는 방식**

> **안전 상태**: 모든 프로세스가 정상적으로 자원을 할당받고 종료될 수 있는 상태
> **안전 순서열**: 특정 순서로 할당, 실행 및 종료를 했을 때 데드락이 발생하지 않는 안전한 순서
> **불안전 상태**: 안전 순서열이 없고 데드락이 발생할 가능성이 있는 상태

- ’한정된 자원을 무분별하게 할당해서 Deadlock이 발생했다’고 간주 -> 배분할 수 있는 자원의 양을 고려하여 **Deadlock 이발생하지 않을 만큼만 자원을 배분**
- 대표적인 알고리즘: **Banker’s Algorithm**
  - 프로세스가 요청하는 자원을 허용하기 전에 `“이 요청을 승인하면 시스템이 안전 상태를 유지할 수 있는가”`를 계산한다. (`요청 → 안전성 검사 → 안전하면 할당`)
  - 하지만 실제 운영체제에서는 거의 사용되지 않는다.
    - **이유**
      - 할당할 수 있는 자원의 수가 일정해야 함.
      - 사용자 수가 일정해야 함.
      - 항상 불안전 상태를 방지해야 하므로 자원 이용도가 낮음.
      - 프로세스들은 유한 시간 안에 자원을 반납해야 함.
      * 모든 프로세스의 최대 자원 요구량(Max), 현재 자원 보유량(Allocated), 시스템의 자원 보유량(Available)을 모두 알아야 함.
        * 대부분의 프로그램은 얼마나 자원을 사용할 지 모르기 때문에 Max를 미리 알기 힘든 경우가 많다.
      * 계산 비용이 큼.
      * 시스템이 매우 복잡해짐.

> [\[운영체제\] The Banker's Algorithm](https://wookkingkim.tistory.com/entry/%EC%9A%B4%EC%98%81%EC%B2%B4%EC%A0%9C-The-Bankers-Algorithm)

### 3) Detection (탐지)
: Deadlock 발생을 **허용**한 뒤 **주기적으로 탐지**하는 방식

- 방법: **Resource Allocation Graph 분석**
  - ’그래프에 **cycle이 존재하면 Deadlock**이다’
  * Database, Distributed system에서 사용됨.

### 4) Recovery (복구)
: Deadlock이 발견되면 시스템을 **정상 상태로 되돌리는 방식**

- 방법
  * **프로세스 강제 종료**
    * Deadlock에 포함된 **프로세스 중 하나 / 전체를** **강제로 종료**한다.
    * 해당 프로세스가 실행 중이던 작업 내용 손실 위험
    * Deadlock이 해결될 때까지 한 프로세스씩 강제 종료하는 경우 **한 프로세스 강제 종료 후 교착 상태가 해결되었는지 확인하는 작업을 반복해야 하기 때문에 시스템에 오버헤드**를 발생시킴 -> 효율 ↓
  * **선점을 통한 자원 회수**
    * Deadlock에 빠진 프로세스 중 하나를 선택하고 그 프로세스가 소유한 자원을 **강제로 빼앗아** 해당 자원을 기다리는 다른 프로세스에 전달한다.
  * **Rollback**
    * 운영체제에서 Deadlock이 발생할 것으로 예측되는 프로세스들에 대해 주기적으로 상태 저장 -> Deadlock 발생 시 **특정 시점**으로 시스템 상태를 되돌린다.

> 문제 발생의 빈도 수나 심각성에 따라서 최대 효율을 추구하기 위해 **Deadlock을 무시**하는 **타조 알고리즘**을 사용하기도 한다.
> (데드락에 아무 대비 없이 컴퓨터 시스템을 가동하고, 데드락 발생 시 시스템을 재시작하거나 특정 스레드를 강제 종료하는 방법으로 해결)

#### 프로세스 중지가 어려운 이유
- 프로세스가 파일을 갱신하는 도중 해당 프로세스를 중지한 경우 -> **수정되던 파일은 부정확한 상태가 됨.**
- 프로세스가 mutex 락을 점유한 상태로 공유 데이터를 갱신하는 도중 중지한 경우 -> **시스템은 락 상태를 사용 가능한 상태로 복구해야 함.**
- 시스템의 선택 상 동일한 프로세스가 항상 중지 대상 프로세스로 선정되는 경우 **기아 현상** 발생 가능 -> 해당 프로세스는 영원히 자신의 작업을 끝내지 못할 수 있다.

#### 중지할 프로세스 선택을 위한 요인
부분적으로 종료하는 방식을 사용할 경우 Deadlock에 빠진 프로세스들 중 어느 프로세스를 중지할지 결정해야 한다.
이때 프로세스를 중지했을 때 **유발되는 비용이 최소인 프로세스를 중지해야** 한다.

1. 프로세스의 우선 순위
2. 지금까지 프로세스가 수행된 시간과 지정된 일을 종료하는 데 더 필요한 시간
3. 프로세스가 사용한 자원 유형의 수
   - 예) 선점할 수 있는 자원인지 여부
4. 프로세스가 종료되기 위해 더 필요한 자원의 수
5. 얼마나 많은 수의 프로세스가 종료되어야 하는지

> [\[OS\] 교착 상태 탐지\(Deadlock Detection\)과 회복 방법 정리](https://howudong.tistory.com/369)

### GCD deadlock
> [\[iOS\] 차근차근 시작하는 GCD — 6](https://sujinnaljin.medium.com/ios-%EC%B0%A8%EA%B7%BC%EC%B0%A8%EA%B7%BC-%EC%8B%9C%EC%9E%91%ED%95%98%EB%8A%94-gcd-6-ae3d0762ae6e)
> [\[iOS\] 차근차근 시작하는 GCD — 14](https://sujinnaljin.medium.com/ios-%EC%B0%A8%EA%B7%BC%EC%B0%A8%EA%B7%BC-%EC%8B%9C%EC%9E%91%ED%95%98%EB%8A%94-gcd-14-4aefd4ba1eb7)

#### 1) 시리얼 큐에서 발생하는 Deadlock
시리얼 큐 = 한 번에 하나의 작업만 실행

- 어떤 시리얼 큐가 현재 작업 A를 실행 중, 작업 A 내부에서 다시 같은 시리얼 큐에 sync로 작업 B를 넣은 경우
  1. 시리얼 큐는 지금 A를 실행 중이다.
  2. A는 B를 같은 큐에 sync로 넣고, B가 끝나길 기다린다.
  3. 하지만 시리얼 큐는 A가 끝나기 전에는 B를 실행할 수 없다.
  4. A는 B를 기다리고, B는 A가 끝나야 실행된다.
  5. **self-deadlock** (reentrant sync 문제)
 

<img width="1159" height="585" alt="스크린샷, 2026-03-19 오후 8 36 38" src="https://github.com/user-attachments/assets/ae9ec37d-2b1f-4e6a-9c33-546d0e43ba14" />


-> 즉 **시리얼 큐에서 sync 호출을 중첩하는 경우** 같은 큐가 자기 자신이 끝나기를 기다리게 되어 deadlock이 발생하게 된다.

<img width="1223" height="790" alt="스크린샷 2026-03-19 오후 6 02 59" src="https://github.com/user-attachments/assets/a1c887e0-1913-4f61-890a-f0b86802339d" />


#### 2) 메인 큐에서 발생하는 Deadlock
**메인 큐도 시리얼 큐**이다. 특별히 UI 작업을 담당하고 메인 스레드와 강하게 연결되어 있다는 특징을 가진다.
따라서 **메인 스레드에서 메인 큐에 sync 호출이 발생하는 경우**에도 메인 스레드가 자기 자신이 끝나기를 기다리게 된다.

1. 메인 큐가 현재 메인 스레드에서 어떤 작업을 실행 중이다.
2. 그 작업 안에서 다시 메인 큐에 sync를 건다.
3. 현재 작업은 새 작업이 끝나길 기다린다.
4. 하지만 메인 큐는 현재 작업이 끝나야 다음 작업을 실행할 수 있다.
5. deadlock (**메인 실행 흐름 자체가 자기 자신을 기다리는 상태**)

- **이미 메인 스레드인 곳에서 main.sync**

<img width="1229" height="888" alt="스크린샷 2026-03-19 오후 6 04 48" src="https://github.com/user-attachments/assets/a410c5ed-58c8-43c1-83cb-a034a1f81fd6" />

- **백그라운드 스레드에서 main.sync**

<img width="1178" height="851" alt="스크린샷 2026-03-19 오후 6 09 36" src="https://github.com/user-attachments/assets/3114c9d5-87dc-4b29-9afc-92bda1a5a0e5" />


- **main.async**는 문제 X
  - 현재 작업은 기다리지 않고 바로 끝나며, 큐는 다음 작업을 실행할 수 있기 때문이다.

-> 따라서 iOS에서 이를 지켜야 한다.
- **메인 큐에서 sync 호출하지 않기 -> async로 호출하기**
- **시리얼 큐 내부에서 동일 큐 sync 호출 피하기**
  - **다른 큐로 호출하기**
  - **async로 호출하기**
- **lock 순서 일관되게 유지하기**

#### concurrent queue에서는?
> concurrent queue = 여러 작업을 동시에 실행할 수 있는 큐
> (작업의 시작 순서만 보장, 실행 완료 순서는 보장하지 X)

같은 concurrent queue에 sync를 보내나고 해서 serial queue처럼 즉시 self-deadlock이 발생하지는 않는다.
**큐가 현재 작업 외에 다른 작업도 실행할 수 있기 때문이다.**

**concurrent queue는 병렬 실행이 가능하지만 wait, sync, lock, semaphore와 같은 blocking 구조를 섞으면 deadlock이 생길 수 있다.**
- 여러 lock이 섞인 경우
- 다른 큐끼리 서로 sync로 기다리며 작업하려 하는 경우
  ```swift
  queueA.sync {
    queueB.sync {
        queueA.sync { }
    }
  }
  
  > 해결: 큐 간 호출은 async로 설계 / 단방향 호출 구조 유지
  ```
- barrier 작업과 대기 구조를 잘못 섞은 경우

<img width="1143" height="923" alt="스크린샷 2026-03-19 오후 6 17 16" src="https://github.com/user-attachments/assets/db6e3a1b-8cde-4e3a-bde2-d1e983406433" />

  1. queue는 concurrent queue다.
  2. barrier 작업이 시작된다.
  3. barrier는 **자기 자신이 실행되는 동안 그 큐에서 다른 작업이 동시에 실행되면 안 된다.**
  4. 그런데 barrier 블록 안에서 다시 같은 큐에 sync를 건다.
  5. sync는 안쪽 작업이 끝날 때까지 기다린다.
  6. 하지만 barrier가 실행 중인 동안에는 같은 큐의 다른 작업을 실행할 수 없다.
  7. 안쪽 작업은 실행될 수 없고, 바깥 barrier는 그 작업이 끝나길 기다린다.
  8. 서로 영원히 기다린다.
  ```swift
  > 해결: barrior 내부에서는 async 사용 / 다른 큐 사용
  ```
- semaphore / group wait를 잘못 사용하는 경우
  - group wait: group에 등록된 모든 작업이 끝날 때까지 현재 스레드를 block한다.
  - (+ group notify: group에 등록된 모든 작업이 완료 후 콜백을 실행한다. 스레드는 계속 진행)
    - wait는 blocking API이기 때문에 주의해야 함.
    ```swift
    > 해결: group.notify와 같은 non-blocking 패턴 사용
    ```

-> 즉 여기서는 **큐 간 상호 대기**나 **동기화 primitive와 결합된 구조**가 문제를 발생시킬 가능성이 높다.

---
#### ++ concurrent queue + group.wait에서 Deadlock 발생?
```swift
let queue = DispatchQueue(label: "concurrent.queue", attributes: .concurrent)
let group = DispatchGroup()

queue.async {
    print("outer start")

    group.enter()

    queue.async {
        print("inner task")
        group.leave()
    }

    group.wait()
    print("outer end")
}
```

실행 흐름
1. 바깥 작업이 queue에서 실행된다.
2. 바깥 작업이 group.enter() 호출
3. 같은 queue에 안쪽 작업을 async로 등록
4. 바깥 작업이 group.wait()로 대기
5. concurrent queue는 다른 작업을 동시에 실행할 수 있으므로, 다른 워커 스레드가 안쪽 작업을 실행할 수 있다.
6. 안쪽 작업이 group.leave() 호출
7. group.wait()가 풀리고 바깥 작업이 계속 진행

-> 정상 동작

<img width="1052" height="854" alt="스크린샷 2026-03-19 오후 6 26 33" src="https://github.com/user-attachments/assets/43d8a05c-a331-4e15-bf0d-3fd9d56a3f6f" />

- 조건별 동작 결과

<img width="4308" height="1562" alt="concurrent queue deadlock" src="https://github.com/user-attachments/assets/7b23f7c9-4754-48b9-83f8-bc464a75edb4" />

<img width="1129" height="834" alt="스크린샷 2026-03-19 오후 6 57 37" src="https://github.com/user-attachments/assets/84ed84fb-bef7-45d2-b619-c461c87a5bec" />


결론
- deadlock의 본질은 async/sync X, **’현재 실행 중인 작업이 자기 자신이 끝나야 실행 가능한 작업을 기다리는지’**이다.
- concurrent queue에 barrior가 붙으면 시리얼 큐처럼 동작한다.
- sync는 대기 상태를 유발하므로 deadlock을 발생하기 쉽게 한다.
---

> **정리**
> OS에서는 Deadlock을 **runtime 알고리즘으로 탐지하거나 복구할 수 있다.** 
> 하지만 GCD 등 애플리케이션 레벨에서는 Deadlock을 자동으로 탐지하거나 복구하는 시스템이 없기 때문에 **설계 단계에서 예방하는 방식이 대부분 사용된다.**

## 3. 의문 / 논점
### Swift Concurrency는 Deadlock 문제를 해결할 수 있을까?
Swift Concurrency는 GCD와 달리 **cooperative thread pool**을 사용한다.

- 작업이 await에 도달 시
  - 현재 작업은 **suspend**
  - 스레드는 **다른 작업 실행에 재사용**
-> 스레드가 대기 구조로 묶이거나, 스레드 풀이 고갈되거나, 스레드 기아 현상이 일어나는 상황이 줄어든다.

즉 기존의 **blocking 기반 동시성 모델**에서 발생하던 Deadlock 가능성이 **줄어들 수 있다.**

하지만 다음과 같은 경우 여전히 발생할 수 있다.
* actor 내부에서 blocking 작업 수행
  * actor 내부에서 sleep, wait, semaphore 같은 blocking 작업 수행 시 actor executor가 해당 작업을 기다리게 된다.
  * 이때 다른 task가 그 actor에 접근해야 한다면 **순환 대기 구조**가 만들어질 수 있다.
* semaphore / DispatchGroup.wait 사용
* sync API 호출

-> 따라서 concurrency 모델이 바뀌어도 Deadlock 문제는 완전히 사라지지 않는다.

