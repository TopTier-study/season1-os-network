## 1. 내가 학습한 주제 / 작업
- 학습 주제: **시스템 콜 메커니즘**
> 아래 내용에서 시스템 콜과 시스템 호출을 같은 용어로 이해해주시길 바랍니다!

## 2. 핵심 개념
### 키워드 정리
- **커널(Kernel)**: 운영체제의 중심. 소프트웨어와 하드웨어 사이의 다리 역할을 수행.
- **XNU**: 애플의 운영체제에서 사용하는 커널의 이름. Mach와 BSD를 결합한 하이브리드 커널.
- **CPU 모드**: CPU가 명령을 실행할 때 가지는 권한 수준.
  - 사용자 모드: 일반 앱이 실행되는 단계. 시스템의 핵심 영역에 접근할 수 없음.
  - 커널 모드: 커널이 실행되는 단계. 모든 하드웨어와 메모리에 접근할 수 있음.
- **시스템 호출(System Call)**: 사용자 프로그램이 사용하는 운영체제 인터페이스
- **svc(Supervisor Call)**: 사용자 모드에서 커널 모드로 진입하기 위한 CPU 명령어

## 3. 탐구 내용
### 1️⃣ iOS에서의 시스템 호출이 발생하는 과정
Swift 코드 -> Foundation 프레임워크 -> **💡 시스템 콜** -> 하드웨어 (파일 읽기, 네트워크 전송 등)

### 2️⃣ 시스템 호출 정리
#### 시스템 호출과 함수 호출의 관계
**시스템 호출은 사용자 모드에서 시작되지만, CPU의 트랩 명령어를 통해 커널 모드로 전환된 뒤 커널 내부 코드가 실행됩니다.**  
반면, **일반 함수 호출은 사용자 모드를 유지한 채 실행됩니다.**  
높은 권한이 필요한 작업은 시스템 호출을 통해서만 수행되며, 이를 통해 일반 애플리케이션이 하드웨어에 직접 접근하는 상황을 방지합니다.  
함수 호출 또한 내부적으로 시스템 호출을 유발할 수 있습니다. (e.g. `print(“”)`)  
라이브러리 함수는 **표준화된 인터페이스를 제공하므로 이식성이 높지만**, 실제 내부 구현은 운영체제에 의존합니다. (e.g. C의 `printf()`는 동일한 방식으로 사용 가능하지만 내부적으로는 OS의 시스템 호출을 사용함)

#### 예시 살펴보기: Swift의 print()에서 커널까지의 여행
1. **Swift 코드**(`print()`): 사람이 사용하는 고수준 함수
2. **Swift 표준 라이브러리**
   - Swift - Misc (cf. `print(“”)`를 `cmd+클릭`해 확인 가능)
   - 이곳에서 LibSystem의 `write()` 호출
3. **LibSystem (C 라이브러리)**: 애플의 시스템 라이브러리 (아직 사용자 수준임!)
   - `write()` 실행 -> 내부에서 `svc`(시스템 콜 트랩) 명령 실행
   - 출력을 하거나 파일에 저장을 할 때 이 라이브러리 `write()`과 커널의 `write`이 둘 다 사용되는 것은 맞으나 이름만 같을 뿐, 사용 영역은 사용자/커널로 다름.
4. **시스템 호출**
5. **CPU 모드 전환**: 사용자 모드 -> 커널 모드
6. **XNU 커널에서 하드웨어 및 파일 시스템 처리**

#### 시스템 호출의 비용 산정
- 사용자 모드와 커널 모드 간의 전환
- 레지스터 저장/복원
- 커널 코드 실행 (요청한 작업 수행)

#### 시스템 호출의 종류 (✍️ 수정 예정)
BSD syscall은 파일/프로세스 같은 **UNIX 전통 기능**, Mach Trap은 메모리/IPC/스레드 같은 **Apple 고유 저수준 기능**을 담당합니다.
[XNU Github - BSD syscall 확인](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/kern/syscalls.master)
[XNU Github - Mach trap 확인](https://github.com/apple-oss-distributions/xnu/blob/main/osfmk/kern/syscall_sw.c)


### 3️⃣ iOS에서 발생할 수 있는 상황 (✍️ 수정 예정)
#### [1] FileManager로 파일 읽기
- 관련 시스템 콜:
- 증상:
#### [2] URLSession 네트워크 요청
- 관련 시스템 콜:
- 증상:
#### [3] DispatchQueue 작업 전환
- 관련 시스템 콜:
- 증상:
#### [4] UIImage(contentsOfFile:)
- 관련 시스템 콜:
- 증상:
#### [5] 잦은 UserDefaults.synchronize()
- 관련 시스템 콜:
- 증상:

### 4️⃣ 추가 학습: Apple’s Darwin OS and XNU Kernel Deep Dive (✍️ 수정 예정)

## 4. 실무 / iOS 연결 지점 (✍️ 수정 예정)
### 문제 상황 재현~개선

## 5. 의문 / 논점 (✍️ 수정 예정)
- 이해가 애매했던 부분
- 토론하고 싶은 질문
- 관점 차이가 발생할 수 있는 부분

## 6. 참고 자료
[ARM64 Exception Level 기초 개념](https://medium.com/@om.nara/aarch64-exception-levels-60d3a74280e6)  
[Apple’s Darwin OS and XNU Kernel Deep Dive](https://tansanrao.com/blog/2025/04/xnu-kernel-and-darwin-evolution-and-architecture/)  
[ARM에서의 Exception Levels와 Security States 이해](https://pyjamacafe.com/posts/arm64-day0-exception-levels/)  
[라이브러리 함수와 시스템 콜 비교 분석](https://mdesign.tistory.com/entry/Unix-%EB%9D%BC%EC%9D%B4%EB%B8%8C%EB%9F%AC%EB%A6%AC-%ED%95%A8%EC%88%98%EC%99%80-%EC%8B%9C%EC%8A%A4%ED%85%9C-%EC%BD%9C-%EB%B9%84%EA%B5%90%EB%B6%84%EC%84%9D)  
