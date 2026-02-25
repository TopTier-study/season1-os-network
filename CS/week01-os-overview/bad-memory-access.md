*해당 문서는 발표 내용보다 더 폭 넓은 내용을 포함합니다.

## 내가 학습한 주제 / 개념

(이전에 학습한 내용)

- 운영체제의 기본적인 정의와 역할
- 컴퓨터 시스템의 구성
    - 인터럽트 개요, 처리 매커니즘
    - 저장 구조, 입출력 구조

(새로 학습한 내용)

- Apple에서 설명하는 EXC_BAD_ACCESS
- ARM 아키텍쳐의 예외 타입 (동기, 비동기)
- XNU 커널에서 EXC_BAD_ACCESS 처리 흐름

## **핵심 개념 / 문제**

- ARM64 아키텍쳐의 예외 종류
- XNU 커널에서 EXC_BAD_ACCESS 예외의 처리 흐름

## **탐구 내용**

### 메모리 참조 오류 EXC_BAD_ACCESS는 어떻게 처리할까?

아키텍쳐 기준: ARM64

### EXC_BAD_ACCESS

**잘못된 메모리 접근으로 프로세스가 종료됨을 알리는 예외 종류** 

---

**EXC_BAD_ACCESS (SIGBUS)**

: 버스에서 오류가 발생해 프로세스가 종료

- **프로세스가 메모리에서 정렬되지 않은 경우**
    - CPU는 명령어를 word 단위로 읽기 때문에 word의 배수 단위로 정렬되지 않은 경우 예외를 발생시킬 수 있다.
        - 예외 발생 이유 → RISC 아키텍쳐의 특징
    - Swift 코드 레벨에서는 컴파일러가 정렬해주므로 거의 발생하지 않음
- **유효하지 않은 주소에 접근하는 경우**
    - 가상 주소 공간에는 있지만, 맵핑되는 실제 물리 메모리 주소가 존재하지 않는 경우
- **포인터 인증에 실패한 경우**
    - ARM64 CPU는 암호학적 서명이 포함된 포인터 인증 코드를 사용하여 메모리 내 포인터의 예상치 못한 변경을 감지하고 보호함.

**EXC_BAD_ACCESS (SIGSEGV)**

: 메모리 결함이 발생해 프로세스가 종료

- **프로세스가 메모리 내에 유효하지 않은 경우**
    - 가상 주소 공간에 주소가 존재하지 않는 경우
- **경계 밖의 주소에 접근하는 경우**
    - Index out of range 같이 주소가 존재하지만, 접근할 수 없는 주소인 경우

---

### 트랩, 인터럽트의 개념적인 차이

|  | 트랩 | 인터럽트 |
| --- | --- | --- |
| 발생 원인 | 실행 중인 명령어 | 외부 하드웨어 |
| 발생 시점 | 동기 (즉시) | 비동기 (언제든) |
| 의도성 | 의도적 / 비의도적 둘 다 | 비의도적 |
| 예시 | SVC, Page Fault, nil 역참조 | 타이머, 네트워크, 터치 입력 |

**핵심 차이**

> 트랩은 "프로그램 내부 코드가 유발", 인터럽트는 "외부에서 끼어듦"
> 

---

### ARM 아키텍쳐의 Exception Types

**Exception의 정의**

**시스템의 원활한 작동을 보장하기 위해 특정 소프트웨어에 의한 보정 조치나 시스템 상태 업데이트가 필요한 조건이나 시스템 이벤트**,  
곧 현재 실행 중인 프로그램이 일시 중지될 수 있는 모든 이벤트를 의미한다.

---

**Synchronous Exception**

현재 실행중인 명령에 의해 발생하거나 관련된 예외로, 현재 실행 스트림과 동기화되어 있다.

ARM 아키텍쳐는 동기 예외에 대해 고정된 우선순위를 제공해 여러 동기 예외가 발생할 경우, 우선순위에 따라 처리한다.

동기 예외를 발생시키는 대표적인 경우는 아래와 같다.

- 잘못된 명령어와 트랩 예외
    - 정의되지 않은 명령어, 비활성화된 명령어 등
    - OS, 하이퍼바이저와 같은 로우 레벨에서 연산을 가로채기 위한 트랩 발생
        - **EL(Exception Level)**
        - ARM은 실행 권한에 따라 Exception Level을 EL0부터 EL3까지 4개로 구분한다. 숫자가 클수록 높은 권한을 가진다.
        - 가령 다른 프로세스 메모리 접근, 하드웨어 제어와 같이 앱(EL0)이 직접 할 수 없는 연산을 시도하면 동기 예외가 발생하고 CPU가 EL1(커널)로 올라가 커널에서 허용 여부를 판단한다.
        
        <img width="762" height="303" alt="image" src="https://github.com/user-attachments/assets/908f3572-8173-40a2-b21b-f2b2a482628c" />

        
- **메모리 접근**
    - **가상 주소를 물리 주소로 맵핑하는데에 실패할 경우 MMU(Memory Management Unit)가 발생시키는 예외**
        - **가상 주소가 페이지 테이블에 없음 (nil 역참조)**
        - **접근 권한 없음 (읽기 전용 영역에 쓰기)**
        - **정렬 오류 (워드 경계를 넘는 접근)**
- 예외 생성 명령어
    - 의도적으로 동기 예외를 발생시키기 위한 명령어
        - 앱에서 시스템 콜을 요청할 경우, 동기 예외를 발생시켜 EL1로 올라간다.
- 디버그 예외
    - 브레이크포인트 명령어와 같은 디버깅 목적으로 발생하는 동기 예외

---

**Asynchronous Exception**

현재 실행 중인 명령어와 직접적으로 연관되어 있지 않으며, 일반적으로 프로세서 외부에서 발생하는 시스템 이벤트, 이를 인터럽트라고 부른다. 

- 물리적 인터럽트
    - 주변 장치에서 외부 신호에 반응하여 발생하는 인터럽트, 코어가 외부 신호를 폴링하는 대신 시스템이 인터럽트를 발생시킨다.
        - 장치 컨트롤러가 CPU에게 데이터 처리 완료 사실을 알려야 할 경우 발생
    - 인터럽트 지연
        - 복잡한 시스템의 경우, 우선순위가 다른 여러 인터럽트 소스를 가질 수 있으며, 중첩된 인터럽트 처리가 가능해 우선순위가 높은 인터럽트가 낮은 인터럽트 핸들러 실행을 가로챌 수 있다.
        - 위의 처리 과정을 포함하여 **인터럽트가 발생한 순간부터 CPU가 실제 인터럽트 핸들러를 실행하는데까지 걸리는 시간을 인터럽트 지연**이라고 하며, 이는 시스템 설계에 중요한 문제가 될 수 있다.
- SError
    - 메모리 시스템에서 예상치 못하게 발생한 시스템 오류
    - 별도의 핸들러를 가지므로 별도의 비동기 예외로 구분됨
    
- IRQ(Interrupt Request) 및 FIQ (Fast Interrupt Request)
    - 보편적으로 interrupt-request line은 인터럽트를 처리하기 위한 CPU의 하드웨어 선을 지칭하지만, ARM에서는 하드웨어 선을 나타내기보다 **CPU가 받는 인터럽트의 타입으로 IRQ, FIQ를 구분**한다.
    - ARM64에서 FIQ는 IRQ보다 우선순위가 높아 더 빨리 처리되어야 하는 인터럽트를 나타낸다.
    - Interrupt Controller
        - 다른 우선순위를 가지는 여러 인터럽트를 받아서 우선순위를 판단하고 IRQ/FIQ로 보내는 역할
        - ARM64에서는 GIC(Generic Interrupt Controller)가 이 역할을 담당한다.
        
- 가상 인터럽트
    - 가상화를 사용하는 시스템의 경우 게스트 OS 입장에서 보이는 인터럽트
    - 하이퍼바이저가 게스트 OS에게 주입해주는 것으로, 실제 디바이스 선과 연결되지 않는다.
    
- 마스킹
    - 모든 비동기 예외는 일시적으로 마스크를 사용할 수 있다.
    - 마스킹 처리가 될 경우, 처리가 지연되며 마스크가 해제되고 예외가 처리될 때까지 “대기” 상태로 존재한다.

---

### EXC_BAD_ACCESS는 어떤 케이스에 해당할까?

이는 실행중인 프로그램 코드에서 잘못된 메모리에 접근하면서 프로세스가 종료되는 예외에 해당하므로 

**메모리 접근에 의한 동기 예외**에 해당함을 알 수 있다.

---

### XNU 소스 분석을 통해 EXC_BAD_ACCESS 발생 흐름 따라가기

**XNU (X is Not Unix)**

: macOS / iOS / iPadOS의 하이브리드식 운영체제 커널

<img width="500" alt="image" src="https://github.com/user-attachments/assets/abd9e31b-355b-411e-bdac-0c1e78495bf8" />


- 구성
    - **Mach(마하)** — 애플이 선택한 마이크로커널. 메모리 관리, 스레드 스케줄링, 프로세스 간 통신(IPC), Mach Exception 처리를 담당.
    - **BSD** — 호환성을 위한 Unix 계열 레이어. 파일 시스템, 네트워크, 시그널(SIGSEGV, SIGBUS) 처리를 담당. **일부 Mach Exception을 받아서 표준 시그널로 변환한다**.
    - **IOKit** — 드라이버 프레임워크. 하드웨어 제어 담당.
- [오픈 소스 코드](https://github.com/apple-oss-distributions/xnu)

---

아래와 같이 마하 커널 기반 서브 시스템을 포함하는 osfmk 디렉터리 아래에  
arm, arm64 등 xnu가 지원하는 아키텍쳐의 폴더와, 공통으로 사용하는 폴더들이 있다.

<img height="400" alt="image" src="https://github.com/user-attachments/assets/bdc74fe9-46e5-4c96-825c-4c5e9d23ecb8" />


여기서는 ARM64를 기준으로 볼 것이기 때문에, 해당 폴더로 이동한다.

폴더로 이동하면, .c 소스파일, .h 헤더 파일, .s 어셈블리어 파일들로 구성되어 있는 것을 확인할 수 있다.

---

**sleh.c 파일**

- **Second Level Exception Handler**
- First level에 해당하는 locore.s 파일로부터 예외를 받는다.
- ARM64 Exception Vector Table에서 넘어온 예외를 받아 알맞는 핸들러 함수를 호출한다.

해당 파일에서 찾고자 하는 오류. **`EXC_BAD_ACCESS`**를 검색하면, 

총 4개의 핸들러 함수에서 `exception_type_t` 타입 변수에 `EXC_BAD_ACCESS` 값을 할당하는 것을 확인할 수 있다.

참고) `exception_type_t` 타입은 exception_types.h 파일에 정의된 정수형을 가리키는 별칭 타입이며, 동일한 파일에는 아래와 같이 여러가지의 예외 타입이 정의되어 있다.

<img height="400"  alt="image" src="https://github.com/user-attachments/assets/d6352d87-68f4-4d81-8afb-6f5d45810364" />


`EXC_BAD_ACCESS` 를 할당하는 4개의 핸들러는 각각 아래와 같을 때 동작한다.

- static void `handle_pc_align`(arm_saved_state_t *ss)
    - PC가 정렬되지 않은 주소를 가리킬 경우
      
- static void `handle_sp_align`(arm_saved_state_t *ss)
    - SP(스택 포인터)가 정렬되지 않은 주소를 가리킬 경우
      
- static void `handle_user_abort`(arm_saved_state_t *state, uint64_t esr, vm_offset_t fault_addr, fault_status_t fault_code, vm_prot_t fault_type, expected_fault_handler_t expected_fault_handler)
    - 유저 공간에서 메모리 접근 오류가 발생했을 경우
      
- static void `handle_pac_fail`(arm_saved_state_t *state, uint64_t esr)
    - PAC(Pointer Authentication Code) 실패가 발생했을 경우 
    (EXC_BAD_ACCESS | EXC_PTRAUTH_BIT) 연산을 통해 예외 타입 지정

해당 파일에는 동기 예외의 종류를 구분하고 핸들러로 분기하는 `sleh_synchronous` 메서드가 존재한다.

1. ESR에서 예외 종류를 추출하고, 유저/커널 모드 여부를 파악한다.
    
    ```c
    esr_exception_class_t class = ESR_EC(esr); // ESR에서 예외 종류 추출
    bool is_user = PSR64_IS_USER(get_saved_state_cpsr(state)); // 유저/커널 판단
    ```
    
2. 예외 종류별로 분기하여 핸들러를 호출한다.
    - `__builtin_unreachable()` : 핸들러에서 항상 프로세스를 종료시키기 때문에 해당 라인이 실행되지 않음을 컴파일러에게 명시하는 최적화 구문
    - `handle_abort`가 `handle_user_abort`를 받는 이유: 같은 abort라도 앱이 발생시켰는지, 커널이 발생시켰는지에 따라 처리가 달라지기 때문에 wrapper 함수로 전달함.
    
    ```c
    // handle_pc_align 호출
    case ESR_EC_PC_ALIGN:
        handle_pc_align(state);       // ← 직접 호출
        
        /* 핸들러가 항상 exception_triage()로 프로세스를 종료시키기 때문에 
        절대 여기까지 실행이 돌아오지 않음 명시 */
        __builtin_unreachable();
    ...
    
    // handle_sp_align
    case ESR_EC_SP_ALIGN:
        handle_sp_align(state);       // ← 직접 호출
        __builtin_unreachable();
    ...
    
    // handle_abort -> handle_user_abort 호출
    case ESR_EC_DABORT_EL0:  // 데이터 접근 오류 (nil 역참조 등)
        handle_abort(state, esr, far, 
                     inspect_data_abort, 
                     handle_user_abort,      // ← 여기서 handle_user_abort 전달
                     expected_fault_handler);
        break;
    
    case ESR_EC_IABORT_EL0:  // 명령어 접근 오류
        handle_abort(state, esr, far, 
                     inspect_instruction_abort, 
                     handle_user_abort,      // ← 동일하게 handle_user_abort 전달
                     expected_fault_handler);
        break;
    ...
    
    // handle_pac_fail 호출
    case ESR_EC_PAC_FAIL:
        handle_pac_fail(state, esr);  // ← 직접 호출
        __builtin_unreachable();
    ```
    

4개의 핸들러 중 `handler_pc_align` 핸들러 내부를 파악해보자.
- 커널/유저 모드 여부를 확인해서 커널 모드일 경우 심각한 상태로 판단하고 시스템을 중단시킨다.
- PAC 기능을 사용하는 경우, 인증 로직을 수행해 포인터 변조로 인해 오류가 발생한 것은 아닌지 검사하고, 인증에 실패했을 경우 예외 타입을 변경하여 보안 관련 문제임을 명시한다.
- 이후 구체적인 오류의 원인과 문제가 발생한 주소를 codes 배열에 저장하고, exception_triage 메서드를 호출하여 예외를 전달한다.

```c
static void
handle_pc_align(arm_saved_state_t *ss)
{
	exception_type_t exc;
	mach_exception_data_type_t codes[2];
	mach_msg_type_number_t numcodes = 2;

  // 커널 모드에서 해당 예외가 발생했을 경우, 심각한 상태이므로 시스템을 중단함.
	if (!PSR64_IS_USER(get_saved_state_cpsr(ss))) {
		panic_with_thread_kernel_state("PC alignment exception from kernel.", ss);
	}
  
  // 이후부터는 유저 모드에서 발생한 예외에 해당.
	exc = EXC_BAD_ACCESS;
	
	// PAC 기능을 사용하는 경우, 포인터 변조로 인해 예외가 발생한 것은 아닌지 검사
#if __has_feature(ptrauth_calls)
	uint64_t pc = get_saved_state_pc(ss);
	if (user_fault_matches_pac_error_code(pc, pc, false)) {
		exc |= EXC_PTRAUTH_BIT; // 인증 실패할 경우, EXC_PTRAUTH_BIT를 추가하여 보안 관련 문제임을 명시
	}
#endif /* __has_feature(ptrauth_calls) */

	codes[0] = EXC_ARM_DA_ALIGN; // 구체적인 오류 원인 명시
	codes[1] = get_saved_state_pc(ss); // 문제가 발생한 실제 메모리 주소를 저장
  
  // EXC_BAD_ACCESS라는 이름의 Mach Exception으로 만들어 해당 스레드에 보냄
	exception_triage(exc, codes, numcodes);
	__builtin_unreachable();
}
```

핸들러에서 마지막에 공통적으로 호출하는 `exception_triage` 함수는 exception.c 파일에 정의되어 있다.

**exception.c 파일**

- 하드웨어 수준에서 발생한 로우 레벨 예외 핸들러가 가장 먼저 호출하는 상위 레벨 함수들이 정의되어 있음.
- 하드웨어 오류를 소프트웨어 언어로 번역하고 **적절한 수신자(핸들러)에게 전달**하는 역할

`exception_triage` 내부에서는 아래와 같은 처리 과정이 일어난다.

1. **컨텍스트 및 하드웨어 환경 검사**

- 가장 먼저 현재 예외가 발생한 **Thread**와 **Task**의 정보를 가져온다.

```c
	thread_t thread = current_thread();
	task_t   task   = current_task();
```

- **Debug4K 체크**: Apple Silicon의 16K 페이지 환경에서 4K 하위 호환성을 테스트 중인 경우, 예외 발생 시 로그를 남기거나 `panic`을 일으켜 시스템을 즉시 중단시킬 수 있다. 이 코드는 메모리 정렬 문제가 시스템 무결성을 해치지 않도록 방어하는 역할을 한다.
    
    ```
    	if (VM_MAP_PAGE_SIZE(task->map) < PAGE_SIZE) {
    		DEBUG4K_EXC("thread %p task %p map %p exception %d codes 0x%llx 0x%llx\n",
    		    thread, task, task->map, exception, code[0], codeCnt > 1 ? code[1] : 0);
    		if (debug4k_panic_on_exception) {
    			panic("DEBUG4K thread %p task %p map %p exception %d codes 0x%llx 0x%llx",
    			    thread, task, task->map, exception, code[0], codeCnt > 1 ? code[1] : 0);
    		}
    	}
    ```
    
2. **개발 및 디버그 이벤트 기록 (Logging)**  
- 만약 시스템이 `DEVELOPMENT` 또는 `DEBUG` 빌드라면, 특정 PID(`exception_log_max_pid`) 이하의 프로세스에서 발생한 예외를 시스템 이벤트 로그에 기록한다. 이는 커널 개발자가 사용자 모드에서 발생하는 정렬 오류의 패턴을 추적하는 데 사용된다.

```c
#if DEVELOPMENT || DEBUG
#ifdef MACH_BSD
	if (proc_pid(get_bsdtask_info(task)) <= exception_log_max_pid) {
		record_system_event(SYSTEM_EVENT_TYPE_INFO, SYSTEM_EVENT_SUBSYSTEM_PROCESS, "process exit",
		    "exception_log_max_pid: pid %d (%s): sending exception %d (0x%llx 0x%llx)",
		    proc_pid(get_bsdtask_info(task)), proc_name_address(get_bsdtask_info(task)),
		    exception, code[0], codeCnt > 1 ? code[1] : 0);
	}
#endif /* MACH_BSD */
#endif /* DEVELOPMENT || DEBUG */
```

3. **PAC(Pointer Authentication) 예외의 특수 처리**

- `EXC_PTRAUTH_BIT`가 설정되어 있는지 체크하고 보안 공격에 대응해야 할 필요가 있는지 확인한다.**
- **`pac_exception_triage`**: 해당 오류가 복구 가능한지 판단한다. 만약 보안 공격(포인터 변조)으로 간주되면, 메시지를 전달하기도 전에 여기서 커널이 실행 흐름을 가로채서 프로세스를 강제 종료하거나 제어권을 회수한다.
  
```c
#if __has_feature(ptrauth_calls)
	if (exception & EXC_PTRAUTH_BIT) {
		exception &= ~EXC_PTRAUTH_BIT;
		assert(codeCnt == 2);
		/* Note this may consume control flow if it decides the exception is unrecoverable. */
		pac_exception_triage(exception, code);
	}
#endif /* __has_feature(ptrauth_calls) */
```


4. **복구 불가능성 판단 (Unrecoverable Check)**
   
- `EXC_MAY_BE_UNRECOVERABLE_BIT`가 포함된 예외라면, `maybe_unrecoverable_exception_triage`를 호출해 시스템이 더 이상 진행할 수 없는 치명적인 상태인지 최종 확인한다.
```c
	if (exception & EXC_MAY_BE_UNRECOVERABLE_BIT) {
		exception &= ~EXC_MAY_BE_UNRECOVERABLE_BIT;
		assert(codeCnt == 2);
		/* Note this may consume control flow if it decides the exception is unrecoverable. */
		maybe_unrecoverable_exception_triage(exception, code);
	}
	return exception_triage_thread(exception, code, codeCnt, thread);
```


5. **최종 목적지 결정: `exception_triage_thread` 호출**

- 모든 필터링과 보안 검사를 통과하면, 이제 이 예외를 “누구”에게 전달할지 결정하는 다음 단계인 **`exception_triage_thread`**로 제어권을 넘긴다.

---

`exception_triage_thread` 에서는 **[스레드 → 태스크 → 호스트]** 순서로 계층을 타고 올라가며 수신자를 찾아 예외를 전달하는 함수 `exception_deliver`를 호출한다.

**1단계: Thread Level (개별 스레드)**

- **대상**: `tro->tro_exc_actions` (Thread Read-Only 데이터 내의 예외 액션)
- **특징**: 예외가 발생한 스레드에만 붙어 있는 디버거가 있다면 여기서 처리하며, 가장 좁은 범위의 핸들러에 해당한다.

**2단계: Task Level (프로세스 전체)**

- **대상**: `task->exc_actions`
- **특징**: 스레드 수준에서 처리되지 않으면, 해당 앱(프로세스) 전체에 설정된 예외 포트를 찾는다. 흔히 아는 Crash Reporter나 프로세스 단위 디버거가 이 단계에서 작동한다.

**3단계: Host Level (시스템 전체)**

- **대상**: `host_priv->exc_actions`
- **특징**: 특정 앱 수준에서도 처리하지 못한 예외를 마지막으로 시스템(OS) 전체 관리자에게 던진다.

**BSD 레이어에서 예외를 처리하는 경우**

- **시스템 부팅 시 BSD 서브시스템은 자신만의 예외 수신 포트인 `ux_handler`를 커널에 등록**한다.
Mach 계층 구조에서 수신자를 찾지 못하면, 예외 메시지는 이 기본 포트로 전달된다.
- **수신 메커니즘**: 이는 함수 내부에서 별도의 BSD 호출 로직을 갖는 것이 아니라, 특정 단계에서 리스트를 순회하다 마지막에 위치한 `ux_handler` 포트에 메시지를 던지는 것이다. 이 메시지를 BSD 전용 스레드가 수신하는 순간 제어권이 BSD로 넘어간다.
- **시그널 변환 (`ux_exception`)**:
메시지를 받은 BSD 레이어는 Mach의 하드웨어 중심적인 예외 언어를 **유닉스 표준인 시그널(Signal)**로 번역한다.
    
    ```c
    	// ux_exception 함수 내부
    	case EXC_BAD_ACCESS:
    		if (code == KERN_INVALID_ADDRESS) {
    			return SIGSEGV;
    		} else {
    			return SIGBUS;
    		}
    ```
    
- **프로세스 종료 (`trapsignal`)**:
번역된 시그널은 `trapsignal` 함수를 통해 해당 프로세스에 던져진다. 앱에 별도의 시그널 핸들러가 없다면, 흔히 보는 "Crash"와 함께 프로세스가 종료된다.

---

`exception_deliver`는 예외 메시지를 단순히 발송만 하지 않고, 보안 환경과 **수신자 권한**에 따라 전달할 데이터의 양과 질을 결정하는 로직을 수행한다.

1. 보안 정책 적용 (PAC 및 Hardening)
- 최신 Apple Silicon(arm64e)에서는 예외 처리를 이용한 공격을 막기 위해 보안 필터를 적용한다.
- Hardened Exception: 예외 액션이 `hardened`로 설정된 경우, 핸들러가 스레드의 모든 레지스터를 수정하지 못하도록 제한한다. 이는 주로 제어 흐름 무결성(CFI)을 보호하기 위해 **PC(Program Counter)** 값 등 핵심 레지스터만 수정 가능하도록 설정하는 방식이다.

2. **동작 방식(Behavior)에 따른 메시지 구성**
- 수신자가 어떤 데이터를 원하는지에 따라 메시지 형식이 달라진다.
- **EXCEPTION_DEFAULT**: 가장 일반적인 형태로, 스레드와 태스크의 **포트(Port)** 정보를 전달.
- **EXCEPTION_STATE**: 예외 발생 당시의 **CPU 레지스터 상태(State)를 포함**한다. 디버거가 실행 중인 코드의 변수 값을 확인하거나 레지스터를 직접 수정할 때 사용된다.
- **EXCEPTION_IDENTITY_PROTECTED**: 실제 포트 대신 **ID 토큰**을 전달하여, 수신자가 프로세스를 직접 제어하는 능력을 제한하는 보안 강화 모델.

3. 권한 검사 (Developer Mode)
- 시스템은 현재 기기가 개발자 모드(Developer Mode)인지 확인한다.
    - **개발자 모드 ON**: 핸들러에게 프로세스를 완전히 제어할 수 있는 **Control Port**를 제공한다.
    - **개발자 모드 OFF**: 보안을 위해 프로세스 정보를 읽기만 할 수 있는 **Read-only Port**만 제공하여, 예외 처리를 통한 임의 코드 실행 공격을 방어한다.

4. **실제 메시지 발송 및 상태 반영**
- **Mach Exception의 통신 모델: RPC (Remote Procedure Call)**
    - Mach 커널은 예외 처리를 위해 단순한 내부 함수 호출이 아닌 **RPC 모델**을 사용한다. 이는 커널이 예외를 직접 해결하지 않고, 외부 핸들러(디버거, 시그널 핸들러 등)에게 처리를 **위임**하여 독립성을 유지하고 유연성을 확보하기 위함이다.
- **동작 메커니즘**
    - **메시지 발송 및 동기적 대기**: 커널은 **`mach_exception_raise_*` 계열 함수를 호출하여 수신자의 포트 큐에 예외 메시지를 넣는다**. 이때 메시지를 발송한 스레드는 핸들러가 답장을 보낼 때까지 **대기 상태**에 진입한다.
    - **상태 반영 및 복구 (Recovery)**: 만약 핸들러가 문제를 해결하거나 레지스터 상태를 수정하여 응답했다면, **커널은 `thread_setstatus_from_user`를 통해 수정된 값을 실제 하드웨어 레지스터에 반영**한다.
    - **재실행**: 모든 반영이 끝나면 스레드는 대기에서 깨어나 **예외 발생 지점(사고 지점)부터 다시 실행**을 시도하는 유연성을 보여준다.
- **처리 결과 반환**
    - 위의 RPC 과정을 마친 뒤, 성공 혹은 실패 여부(처리 결과)를 `exception_triage_thread`로 반환한다. 만약 실패(`KERN_FAILURE`)가 반환된다면, 커널은 다음 단계로 넘어가 같은 매커니즘을 실행하거나, 실패 처리하여 프로세스 자원을 회수하고 강제 종료한다.

### 처리 매커니즘 도식화

<img width="1991" height="1585" alt="image" src="https://github.com/user-attachments/assets/b87f9d87-b768-4c5a-887f-89db3e638756" />


## 실무 / iOS 연결 지점

### Swift 런타임에서 발생하는 ‘Fatal Error’는 어떻게 처리될까?

- 

## 의문 / 논점

- 

## 관련 링크

https://developer.apple.com/documentation/xcode/exc_bad_access

https://developer.arm.com/documentation/102412/0103/Exception-types

https://github.com/apple-oss-distributions/xnu
