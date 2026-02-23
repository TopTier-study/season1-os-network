## WEEK 4 — Deadlock + Blocking & I/O 사고

### 📖 학습 키워드
1. Deadlock 조건
2. Deadlock 해결 전략
3. Blocking vs Non-Blocking
   * I/O Blocking
   * 왜 스레드가 묶이는가
   * 네트워크 호출과 Blocking
   * 비동기 모델 필요성

### 📢 발표 주제
#### ① Deadlock 발생 조건

- Mutual Exclusion
- Hold & Wait
- Circular Wait

#### ② Deadlock 해결 전략

- Prevention
- Avoidance
- Detection

#### ③ Blocking vs Non-Blocking 본질

- Blocking 의미
- 왜 문제인가
- 자원 관점 해석

#### ④ I/O Blocking 문제

- 디스크 / 네트워크 공통 구조
- 스레드 정체 현상
- 대기 메커니즘

#### ⑤ 네트워크 호출 & 스레드 문제

- 왜 UI가 멈추는가
- 비동기 필요성
- 실제 앱 문제 연결

#### ⑥ 비동기 모델 등장 이유

- Event Loop 사고
- 비동기 구조 필요성
- 성능 관점
