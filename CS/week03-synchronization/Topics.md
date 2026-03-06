## WEEK 3 — 동기화 & 경쟁 상태

### 📖 학습 키워드
1. Race Condition
   * 발생 조건
   * 위험성
2. Critical Section
   * Mutual Exclusion
   * 기본 조건
3. 동기화 도구
   * Mutex
   * Semaphore

### 📢 발표 주제
#### ① Race Condition의 본질 - 성국

- 발생 조건
* 왜 위험한가
* 실제 버그 사례

#### ② Critical Section 문제 - 귀로

* 공유 자원 문제
* Mutual Exclusion 필요성
* 기본 조건

#### ③ Mutex 메커니즘 - 지연

* 락 개념
* 동작 방식
* 장단점

#### ④ Semaphore 메커니즘 - 상유

* 카운팅 vs 바이너리
* Mutex와 차이
* 사용 목적 차이

#### ⑤ 동기화 비용 & 성능 문제 - 선재

* 락 경합
* 병목 발생
* 성능 저하 원인

#### ⑥ 실무 문제 상황 사고 - 윤서

* 데드락 위험
* 락 설계 전략
* 실제 서비스 장애 연결
