## WEEK 4 — Deadlock + Blocking + Memory Management

### 📖 학습 키워드
#### 동시성 문제
1. Deadlock 조건
2. Deadlock 해결 전략
3. Blocking vs Non-Blocking
    - Blocking 의미
    - I/O Blocking
    - 네트워크 호출과 Blocking
    - 왜 스레드가 묶이는가

#### 메모리 관리
1. Logical vs Physical Address
2. Paging 개념
    - Page / Frame
    - 등장 배경
3. Virtual Memory
    - 필요성
    - Page Fault 개념

### 📢 발표 주제
#### ① Deadlock 발생 조건 - 상유

- Mutual Exclusion
- Hold & Wait
- No Preemption
- Circular Wait
- 왜 이 조건들이 동시에 필요할까

#### ② Deadlock 해결 전략 - 지연

- Prevention
- Avoidance
- Detection
- Recovery 전략

#### ③ Blocking vs Non-Blocking 본질 - 선재

- Blocking 의미
- 자원 대기 관점
- 스레드 정체 현상
- 왜 성능 문제가 되는가

#### ④ I/O Blocking 문제 - 귀로

- 디스크 / 네트워크 공통 구조
- 스레드 대기 메커니즘
- OS가 대기를 처리하는 방식

#### ⑤ Logical vs Physical Address - 성국

- 왜 주소 변환이 필요한가
- 프로그램이 보는 주소 vs 실제 메모리
- OS와 MMU 역할

#### ⑥ Paging & Virtual Memory - 윤서

- Paging 등장 배경
- Page / Frame 구조
- Page Table
- Page Fault 비용
