# CPU 스케줄링 알고리즘 종류

## 학습 키워드

- CPU Scheduling
- Burst Cycle, 선점형 / 비선점형
- FCFS, SJF, SRTF, Priority, RR, MLQ, MLFQ
- Starvation, Aging

## 1. 핵심 개념

### CPU 스케줄링 정의 및 배경

- **CPU 스케줄링**
    - 각 프로세스에 어떻게 cpu의 사용을 할당할 것인가를 결정하는 과정
- **Multiprogramming 기반**
    - 하나의 프로세서에 여러 프로그램이 **concurrent**하게 실행되는 환경 전제
- **Ready State**
    - 메모리 내의 대기 중인 프로세스들 중 하나를 cpu에 할당
- **이상적 스케줄러 조건 (100% 만족하기는 어렵지만, 시스템 용도에 따라 우선순위 상이):**
    - 최대의 cpu 사용률
    - 최대의 cpu 처리량
    - 최소의 응답 / 대기시간
      
----

### CPU-I/O Burst Cycle

- **사이클 구성:** 프로세스 실행은 CPU 실행(CPU burst)과 I/O 대기(I/O burst)로 구성
- **실행 흐름:** CPU burst 시작 → I/O와 CPU burst 교차 → 마지막 CPU burst 종료
- **CPU burst time 특징:** 걸리는 시간이 짧을수록 빈번하게 나타나는 경향
    - **I/O-bound program:** 많은 수의 short-CPU bursts를 가짐
    - **CPU-bound program:** 적은 수의 long-CPU bursts를 가짐

----

### 비선점형 방식과 선점형 방식

- **비선점형 방식 (Non-preemptive):**
    - cpu 할당 시 프로세스 종료까지 할당 유지
    - 스스로 자원 반납 전까지 타 프로세스 할당 불가
    - 종료 후 다음 process 할당 시 context switching 발생
- **선점형 방식 (Preemptive):**
    - 실행 중인 프로세스가 있어도 Ready Queue의 다음 프로세스가 cpu 강제 점유 가능
    - **결정 방식:** 현재와 다음 프로세스의 cpu burst time 비교 (남은 시간이 더 짧으면 교체)
    - **비용:** 프로세스 교체 시 context switching 비용 발생

----

### Scheduling Criteria (스케줄링 알고리즘 성능 지표)

- **CPU Utilization:** CPU가 놀지 않고 일한 시간 비율 (40~90% 유지 목표)
- **Throughput:** 특정 시간 동안 처리된 프로세스의 수
- **Turnaround time:** Ready queue 진입부터 실행 완료까지의 시간 (대기 + 처리 시간)
- **Waiting time:** Ready queue에서 대기한 시간의 총합
- **Response time:** 진입 시점부터 시스템에 의해 처리 시작 전까지의 시간 (반응성 중요 시스템 핵심)

----

### 주요 알고리즘 상세

- **FCFS (First-Come, First-Served):**
    - 먼저 요청한 프로세스 우선 처리 (비선점형)
    - FIFO queue 사용, 단순 구현 가능하나 대기 시간 변동 큼
    - **Convoy Effect:** 긴 프로세스가 CPU 점유 시 짧은 프로세스들이 하염없이 기다리는 자원 낭비 상황

- **SJF (Shortest Job First):**
    - Burst Time 가장 짧은 것부터 처리 (비선점형)
    - 평균 waiting time 감소로 FCFS 보완 가능
    - **Approximate SJF:** 미래 burst time 예측 불가로 과거 데이터 기반 추정 방식 사용

- **SRTF (Shortest Remaining Time First):**
    - 남은 Burst Time 짧은 것 우선 처리 (선점형 SJF)
    - 현재 남은 시간보다 짧은 프로세스 생성 시 CPU 양보
    - **평균 대기 시간 예시:** (9+1+0+2)/4 = 3

- **Priority Scheduling:**
    - 우선순위 높은 프로세스 우선 처리 (선점/비선점 모두 가능)
    - **내부적 요소:** 제한 시간, 메모리 요구량, 오픈 파일 수, I/O 비율 등
    - **외부적 요소:** 프로세스 중요도, 사용자 부서, 정책적 요인 등
    - **Starvation (기아 현상):** 낮은 순위 프로세스가 영원히 할당받지 못하는 현상
    - **Aging (에이징):** 대기 시간에 비례해 우선순위를 높여 기아 현상 방지
    - [전공 과제 참고 자료 [xv6에서 Priority Scheduling 구현기. 옛날 포스팅이라 두서 없음 주의]](https://blog.naver.com/sunjaenation/223267053013)

- **RR (Round Robin):**
    - 일정 **Time Quantum(q)** 정하여 순차 할당 (선점형)
    - q가 지나면 대기 열 재진입, 타이머 인터럽트 발생
    - q가 크면 FCFS와 유사, q가 context switching 시간보다 작으면 효율 급감

- **Multi Level Queue (MLQ):**
    - Ready Queue를 여러 개 분할하여 상위 레벨 큐에 CPU 우선 할당
    - **우선순위:** 시스템 작업 > 대화형 작업 > 대화형 편집 > 일괄(batch) 처리 > 학생 작업(시스템에 큰 영향을 주지 않는 낮은 우선순위 작업)
    - 큐 간 이동 불가로 유연성 낮고 기아 현상 가능성 존재

- **Multi Level Feedback Queue (MLFQ):**
    - 우선순위가 낮은 큐에 있더라도 Aging에 의해 우선순위가 높은 큐로 이동할 수 있다.
    - 따라서 **큐의 개수**, **각 큐에서 사용할 스케줄링 알고리즘**뿐만 아니라
    **언제 process를 한 단계 높은 큐로 이동할지 / 한 단계 낮은 큐로 이동할지**,
    **어떤 프로세스가 특정 service를 요구할 때 그것을 제공하는 큐로 옮겨줄 방법**은 무엇인지 등의 복잡한 의사 결정이 필요하다.
    - 프로세스의 큐 간 이동 가능
    
    <img width="400" alt="image" src="https://github.com/user-attachments/assets/e9996d94-0600-4ecc-b6da-5445d76d12c6" />

    
    - 위에 있을 수록 우선순위가 높으며 time qunatum 값이 적고, 맨 아래의 가장 우선순위가 낮은 큐에서는 FCFS로 처리한다고 가정하면,
        - **동작:** Q0(TQ=8) → 못 끝내면 Q1(TQ=16) → 못 끝내면 Q2(FCFS) 이동
        - 결국 CPU-bound는 아래 단계로, I/O-bound는 위 단계에 위치하게 된다.

## 2. 탐구 내용 (실무 / iOS 연결)

## 3. 의문 / 논점

## 4. 참고 자료

- Operating System Concepts 10th
