## 1. 내가 학습한 주제: iOS의 앱 Launch

## 2. 핵심 개념 / 문제
### 1) rebase
: Mach-O 바이너리가 빌드 시 가정한 기준 주소(base address)와 실행 시 실제 로드된 주소가 달라질 때 **내부 포인터 값을 보정**하는 작업

#### rebase 발생 원인
앱 바이너리 내에 있는 메타데이터의 주소는 앱 실행 시 ASLR(Address Space Layout Randomization, 운영체제 메모리에 로드되는 실행 파일 위치를 무작위로 생성하여 여러 공격으로부터 보호하는 기술)에 의해 실제 로드 주소가 달라지기 때문이다.

#### rebase 소요 시간
**포인터가 많을수록** 수정량이 많아져서 rebase에 소요되는 시간이 증가한다.

**Objective-C 메타데이터**는 클래스, 메서드 리스트, 프로토콜 리스트 등 많은 포인터를 포함하기 때문에 rebase **비용을 증가**시킬 수 있다.

- **Rebase 비용이 커지는 상황**
  * 클래스 수 많음
    * Swift 클래스는 기본적으로 Swift runtime 메타데이터를 가짐
    * `@objc` 노출 시 Objective-C runtime에도 등록됨
    * NSObject 상속 시 ObjC 런타임과 연결됨
  * 전역 static 많음
  * ObjC 런타임 노출 많음
  * dynamic framework 많음
  * 포인터 기반 구조 많음
- **최적화 전략**
  * 불필요한 `@objc` 제거
  * 전역 포인터 줄이기
  * dynamic framework 최소화
  * static linking 전략 검토
  * 메타데이터 과다 생성 방지

> [참고\) Why Swift Reference Types Are Bad for App Startup Time](https://medium.com/geekculture/why-swift-reference-types-are-bad-for-app-startup-time-90fbb25237fc)

### 2) bind
- 외부 심볼을 실제 주소에 연결하는 작업
- ex) `print("hi")`
  - print는 사용자의 바이너리에 없고 Foundation / Swift runtime에 있음.
  - 그러므로 해당 함수 주소를 찾아 연결해야 함.

### 3) dyld
- 각 프로세스가 시작될 때 실행
- 프로세스의 주소 공간 안에서 동작 (**프로세스 단위**)
- **런치 시 동작**
  1. Mach-O의 __LINKEDIT(링킹 메타데이터 저장)를 읽어서 rebase / bind 정보를 가져옴.
  2. 심볼 해결 (심볼이 많으면 bind가 많음)
  3. __DATA 수정
- 그러나 iOS 13+부터 사용되는 **dyld3의 launch closure**는 의존 라이브러리 그래프, rebase / bind 정보, 초기화 순서를 미리 계산 후 closure 형태로 **디스크에 저장** -> __LINKEDIT 접근 감소, bind / rebase 계산 감소, 런치 가속
  - 즉 앱이 종료되어도 남아있을 수 있음. (재부팅해도 보통 유지됨)
    - **재부팅 시 사라지는 것**
      - page cache
      - 메모리에 매핑되어 있던 __TEXT 페이지
      - 일부 메모리 기반 최적화 상태
    - -> dyld3 closure가 남아있어도 파일을 디스크에서 다시 읽는 I/O 비용이 크기 때문에 런치 속도에 영향 O
  - 앱 업데이트 / OS 업데이트 시 무효화

### 4) dyld shared cache
- 시스템 전역 캐시 (**시스템 단위**)
- UIKit, Foundation 등 묶여 있음.
- iOS 부팅 시 준비됨.
- 모든 앱이 공유

## 3. 탐구 내용

### iOS 앱 런치 타입
#### 1) Cold Launch
: 앱을 **처음부터 실행**시키는 런치

- 조건
  - 아이폰 부팅 후
  - 앱이 메모리에 없음.
  - 앱 프로세스가 없음.
- 동작
  1. 디스크에서 바이너리 로드
  2. dyld3로 라이브러리 및 프레임워크 링크
  3. 프로세스 fork / exec

앱을 시작하기 위해서는 디스크에서 메모리로 가져온 후, 앱을 지원하는 시스템 서비스를 시작한 후 프로세스를 실행해야 한다.

#### 2) Warm Launch
: **캐시를 재활용**하는 런치

- 조건
  - **앱이 최근에 종료**된 경우
    - page cache가 남아있을 가능성 높음.
    - __TEXT 페이지가 메모리에 있을 수 있음.
    - 디스크 접근 거의 없음.
  - 앱이 부분적으로 메모리에 캐시 존재
    - 앱 바이너리 파일이 일부 메모리에 올라가 있다 = 페이지 캐시가 살아 있다
  - 앱 프로세스가 없음.
- 동작
  1. dyld3 런타임 종속성 캐시 활용
  2. 프로세스 재생성
- 특징
  - 앱이 정상적으로 종료되면 **프로세스 같이 죽음**.
  - 그러나 운영체제의 파일 / 페이지 캐시 및 dyld shared cache 등 시스템 레벨 자원이 유지되어 있기 때문에 Cold Launch보다 빠르게 실행됨.

#### 3) Resume Launch
: 앱이 백그라운드에서 **suspended** 상태였다가 돌아올 때의 런치

- 조건
  - 앱이 일시 중지 상태 (suspended)
  - 앱 메모리 그대로 존재
  - 프로세스 이미 존재
- 동작
  1. 프로세스 재개 (메모리 그대로)
  2. 즉시 이벤트 처리

### 앱 런치 과정

Apple은 첫 번째 프레임을 **400ms 미만**으로 그릴 것을 권장한다.

![](iOS%E1%84%8B%E1%85%B4%20%E1%84%8B%E1%85%A2%E1%86%B8%20Launch/%E1%84%89%E1%85%B3%E1%84%8F%E1%85%B3%E1%84%85%E1%85%B5%E1%86%AB%E1%84%89%E1%85%A3%E1%86%BA%202026-02-27%20%E1%84%8B%E1%85%A9%E1%84%8C%E1%85%A5%E1%86%AB%202.47.34.png)

#### 1. System Interface (100ms)
- **커널이 파일 열고 링크 시작**
  - 커널이 **exec 시스템 콜로 Mach-O 바이너리를 매핑**
  - **dyld3 동적 링커**가 라이브러리 / 프레임워크를 동적으로 링크
    - **프레임워크 동적 로드는 권장 X** 
- iOS 13+에 도입된 dyld3에서 개선된 내용: Warm 런치 시 이전 링크 결과 캐시 재사용 → 반복 실행 빠름.
  - dyld3는 앱 실행 시 필요한 동적 링킹 정보를 미리 계산해둔 **launch closure**를 활용 -> 런치 시점의 동적 라이브러리 의존성 분석과 심볼 바인딩 비용을 줄여준다.
  - 이는 앱 프로세스가 종료되더라도 시스템 차원에서 유지될 수 있기 때문에 warm launch가 cold launch보다 빠른 핵심 원인이 될 수 있다.
- libSystem init: 저수준 시스템 인터페이스(파일·네트워크 fd 등) 초기화
  - 고정 비용 작업

#### 2. Runtime Init (100~150ms)
- 프로세스 메인 스레드에서 클래스를 등록하고 메타데이터 초기화
  - Objective-C: `+load` 메서드들 순서대로 호출
  - Swift: 정적 초기화(`static var, static let`) 실행
- **주의점**: 무거운 `+load`(데이터베이스 연결 등)은 메인 스레드 블로킹 → Cold/Warm 둘 다 느려짐.
- **해결 전략**: `+initialize`로 지연시키거나 백그라운드 DispatchQueue로 무거운 작업 이동시키기

> `+`: Objective-C에서 클래스 메서드를 의미
> `+load`: 앱 시작과 거의 동시에 **클래스가 메모리에 올라오는 순간** 실행 (앱 시작 속도에 영향)
> `+initialize`: **해당 클래스를 처음 사용할 때** 실행 (클래스 당 1번 실행)

#### 3. UIKit Init (150 ~ 200ms)
- `UIApplication.shared` -> UIWindow 생성 -> rootViewController 설정
- **운영체제**: 메인 스레드 RunLoop 시작, CADisplayLink 연결
- **최적화 전략**: UIApplication 서브클래스 피하고 SceneDelegate(iOS 13+) 활용하기

#### 4. Application Init (200 ~ 300ms)
- 운영체제가 **백그라운드 프로세스와 스레드 우선순위 조정**
- 이때 네트워크 요청 / 파일 I/O가 포함되면 앱 런치 400ms 초과 -> 첫 프레임 지연

#### 5. Initial Frame Render (300 ~ 400ms)
- `loadView() → viewDidLoad() → viewWillAppear() → layoutIfNeeded()`
- 운영체제에서는 Core Animation이 뷰 계층을 GPU로 전송
- **복잡한 오토레이아웃 제약 조건 있을 시** Metal 렌더링 대기로 인한 **병목** 발생 가능성

#### 6. Extended
- 첫 프레임이 나온 시점부터 모든 프레임이 다 나오기까지의 구간
- 비동기적인 데이터를 로드하여 보여줌.
- 모든 앱이 다 이 구간이 있는 것은 아님.

> [참고 1\) WWDC 2019: Optimizing App Launch](https://developer.apple.com/videos/play/wwdc2019/423/)
> [참고 2\) Apple Developer: Reducing your app’s launch time](https://developer.apple.com/documentation/xcode/reducing-your-app-s-launch-time)
> [참고 3\) Stack Overflow: What’s difference between cold launch, warm launch?](https://stackoverflow.com/questions/69623550/whats-the-difference-between-cold-launch-warm-launch)

## 4. 실무 / iOS 연결 지점 

### 메모리 부족으로 인해 앱 프로세스가 강제 kill된 후 다시 실행할 때의 런치 타입은 무엇일까?
- 상황: 메모리 부족으로 인해 jetsam(iOS의 OOM 킬러)이 앱 프로세스 강제 kill(SIGKILL) 후 동일 앱 다시 실행
- 이 때의 런치 타입은 **Cold Launch**이다.
  - 종료 시에 프로세스는 완전 종료되고(terminated) 메모리에서 전체 해제되며 dyld3 캐시도 무효화됨.

#### jetsam
: iOS 커널의 메모리 압박 관리자

- 각 프로세스에 우선순위(포그라운드: 높은 순위 / 백그라운드: 낮은 순위)를 매겨 RAM 부족 시 낮은 우선순위인 백그라운드 앱부터 순차적으로 kill
- kill 당한 앱은 **프로세스 테이블에서 완전 제거** -> PID 소멸 -> 메모리 페이지 테이블 해제 -> dyld3 런타임 캐시 무효
- 따라서 앱이 이후 재실행되는 경우에는 exec부터 새로 시작한다.
