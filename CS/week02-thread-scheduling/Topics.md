## WEEK 2 — 스레드 & CPU 자원 분배

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
#### ① 스레드 등장 배경

- 왜 프로세스만으로 부족했는가
- 경량 실행 단위 필요성
- 동시성 문제와 연결

#### ② 스레드 vs 프로세스

- 주소 공간 공유
- 자원 공유 의미
- 구조적 차이
- 장단점 비교

#### ③ 스레드 생성 비용 & 컨텍스트 스위칭 차이

- 왜 스레드가 가벼운가
- 프로세스 vs 스레드 비용 차이
- 성능 영향

#### ④ CPU 스케줄링의 존재 이유

- 왜 스케줄러가 필요한가
- 선점 vs 비선점
- 자원 분배 문제

#### ⑤ 스케줄링 알고리즘 비교

- FCFS
- SJF
- Round Robin
- 전략별 특징 & trade-off

#### ⑥ 성능 관점 사고

- Throughput vs Latency
- Response Time
- 실제 서비스 관점 연결
- 사용자 경험 영향
