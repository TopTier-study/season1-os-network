# HTTP
### 학습 키워드
- HTTP
- 쿠키
- 웹 캐싱(proxy server)
## 1. 핵심 개념
### 개요
- HTTP: HyperText Transfer Protocol
- HTTP 통신 구성: 서버 프로그램, 클라이언트 프로그램
	- HTTP가 정의하는 것: 클라이언트가 어떻게 요청하는지, 서버가 클라이언트로 어떻게 웹 페이지를 전송하는지
- 웹 페이지: 객체로 구성된 문서. 보통 기본 HTML 파일과 여러 참조 객체로 구성.
- 객체: 단일 URL로 지정할 수 있는 하나의 파일. HTML파일, JPEG 이미지, 자바스크립트, CSS 스타일 시트 파일, 비디오 클립 등)
- URL 구성: 'google.com/search?q=' 에서 google.com이 호스트, 그 이후가 객체의 경로 이름. 
- TCP 전송 프로토콜 사용.
- 각 프로세스는 소켓을 인터페이스로 통신.
- 서버는 클라이언트의 상태를 저장하지 않음: 비상태 프로토콜(stateless protocol)
	- 서버는 잠재적으로 수많은 클라이언트와 통신할 것이기 때문.
### 지속 연결, 비지속 연결
#### 비지속 연결 HTTP
1개의 HTML 파일과 10개의 이미지를 전송하는 상황에서, 각 객체를 전송할 때 TCP를 개설하고, 클라이언트가 서버에 요청하고, 그 응답이 성공적으로 전달되면 TCP 연결을 닫는다. 즉 11개의 객체를 전송할 때 11번 TCP를 개설하는 방식이다. 
#### 비지속 연결 파일 수신 시간
RTT: round-trip time, 작은 패킷이 클라이언트로부터 서버까지 가고, 다시 클라이언트로 되돌아오는 데 걸리는 시간. 패킷 전파 지연, 라우터와 스위치에서의 패킷 큐잉 지연, 패킷 처리 지연 등을 포함한다. 
클라이언트는 서버에 TCP 연결을 시도하고, 서버는 응답을 보낸다. (여기까지 1RTT) 클라이언트는 다시 3 way handshake의 마지막과 함께 서버에 요청을 보내고, 서버는 HTML파일을 보내준다. (1RTT + HTML파일 전송 시간.)
따라서 파일 수신에 걸리는 시간은 2RTT + HTML 파일 전송 시간이다. 
#### 지속 연결 HTTP
HTTP/1.1 이후 기본이 되는 방식. 한 번 연결한 TCP 연결을 바로 끊지 않고 일정 시간 동안 열어두면서 여러 개의 HTTP 요청과 응답을 주고받는다. 
### HTTP 메시지 포맷
#### 공통 구조
- 시작 줄: 요청이나 응답 상태를 나타내는 첫 번째 줄
- 헤더: 요청/응답에 대한 속성, 메타데이터를 키-값으로 표현
- 빈 줄: 헤더와 본문 사이에 삽입되어 둘을 구분.
- 본문: 실제로 전송할 데이터(HTML, JSON 등), 생략 가능
- 각 줄은 CR(carriage return), LF(line feed)로 구별된다. 
- 메시지는 ASCII 텍스트로 구성된다.
#### 요청 포맷
```
GET /users/123 HTTP/1.1 
Host: api.example.com  
User-Agent: iOS-App/1.0
Accept: application/json
Content-Type: application/json

{
  "name": "홍길동",
  "age": 27
}
```
- 요청 라인: 요청 메시지의 첫 줄. method 필드, URL 필드, HTTP 버전 필드를 갖는다. 
	- method 필드: GET, POST, HEAD, PUT, DELETE 등
- 헤더: 2번째 줄부터 헤더. 문법상 헤더 개수는 0개 이상. 하지만 실제로는 HTTP/1.1 버전부터 클라이언트가 요청을 보낼 때 HOST 항목이 필수.
	- Connection: 지속 연결 사용 여부.
	- User-Agent: 서버에게 요청을 하는 브라우저 타입.
	- Accept-Language: 원하는 객체 언어. 없으면 기본 타입으로 반환될 수 있다.
- body(본문): GET 방식에서는 비어있고, POST 방식에서 사용된다. HEAD는 GET과 유사하나 요청 객체는 보내지 않아 디버깅에 자주 사용된다. PUT 방식은 웹 서버에 업로드할 객체를 필요로 하는 어플리케이션에 의해 사용된다. DELETE는 서버의 객체를 지우는 것을 허용한다. 
#### 응답 포맷
```
HTTP/1.1 200 OK 
Date: Thu, 02 Apr 2026 01:35:00 GMT
Content-Type: application/json
Content-Length: 45
Cache-Control: max-age=3600

{
  "status": "success",
  "message": "요청이 성공했습니다."
}
```
- 상태 라인: 시작 줄, 버전 필드, 상태 코드, 해당 상태 메시지의 3가지 필드로 구성. 
	- 버전 필드: HTTP 버전
	- 상태 코드: 요청의 성공/실패 여부를 나타내는 3자리 숫자(200 성공, 404 찾을 수 없음, 500 서버 에러 등)
	- 상태 메시지: 상태 코드를 사람이 읽기 쉽게 짧게 글로 표현한 것(OK, Not Found)
- 헤더
	- Connection: 클라이언트에게 메시지를 보낸 후 TCP 연결을 닫을지
	- Date: HTTP 응답이 서버에 의해 생성되고 보낸 날짜와 시간. 
	- Server: 만들어진 서버 정보(아피지 웹 서버 등)
	- Last-Modified: 객체가 새엇ㅇ되거나 마지막으로 서정된 시간과 날짜. 
	- Content-Length: 송싱되는 객체 바이트 수
	- Content-Type: Body의 객체 종류 정보. 확장자 대신 Content-Type 헤더로 나타남.
### 쿠키
HTTP 서버는 기본적으로 상태를 유지하지 않으나, 서버가 사용자 접속을 제한하거나 사용자에 따라 콘텐츠를 제공하는 목적으로 웹사이트가 사용자를 확인해야 할 경우 쿠키를 사용한다. 
- 동작 원리
	- 발급: 사용자가 접속하면, 서버는 식별번호를 만들고 이 식별번호로 인덱싱되는 DB 안에 엔트리를 만든다. 또 응답으로 Set-Cookie 헤더에 식별번호를 보내준다.
	- 저장: 브라우저는 받은 쿠키 파일을 관리, 저장한다.
	- 요청: 이후 클라이언트는 같은 도메인으로 HTTP 요청을 보낼 때, 저장해 둔 쿠키를 요청 해더의 cookie 항목에 포함한다.
	- 인식: 서버는 쿠키를 바탕으로 사용자를 인식하고, 이에 맞는 정보를 내려줄 수 있다.
- 주요 사용 목적
	- 세션 관리: 로그인 상태 유지, 쇼핑몰의 장바구니, 게임 점수 등 사용자의 인증 및 상태 정보
	- 개인화: 다크모드/라이트모드 설정, 언어 설정 등
	- 트래킹: 사용자가 주로 방문한 페이지 정보(맞춤형 타겟 광고)
### 웹 캐싱
프록시 서버(proxy server)라고도 함. 기점 웹 서버를 대신하여 HTTP 요구를 충족시키는 네트워크 개체. 자체의 저장 디스크를 가져 최근 호출된 객체의 사본을 저장 및 보존한다. 
- 동작
	- 브라우저는 웹 캐시와 TCP 연결을 설정하고 웹 캐시에 있는 객체에 대한 HTTP 요청을 보낸다.
	- 웹 캐시는 캐시의 Hit, Miss 여부를 확인한다.
	- Hit할 경우 해당 객체를 반환한다.
	- Miss일 경우 기점 서버로 TCP 연결을 설정하고, 객체를 요청해 받아온다. 
프록시 서버는 ISP(회사, 대학교 통신사 등)가 주로 구입하고 설치하여 작동하게 된다.
웹 캐싱을 사용하면 다음의 이점을 얻을 수 있다.
- 장점
	- 응답 속도 향상: 먼 거리에 있는 원본 서버와 통신할 필요가 없음.
	- 서버 부하 감소: 원본 서버가 똑같은 요청을 반복해서 처리할 필요가 없어져 서버의 컴퓨팅 자원을 아낄 수 있다. 
	- 인터넷 전체의 웹 트래픽을 실질적으로 줄일 수 있다. 
#### CDN
전 세계 곳곳에 흩어져 있는 대규모 분산 캐시 서버. 많은 트래픽을 지역화 할 수 있다. 
#### 조건부 GET
캐싱된 데이터를 사용하는 것은, 해당 데이터가 최신 데이터가 아닐 가능성을 야기한다. 이럴 경우 조건부 GET을 사용한다. 마지막 수정 시간을 보내 서버의 최신 데이터와 일치하는지 확인하고, 일치할 경우에는 객체를 포함하지 않은 메시지를 보내 클라이언트가 캐싱된 복사본을 사용할 수 있게끔 한다.
### HTTP/2
TCP 연결상에서 멀티플렉싱 요청/응답 시간 감소, 요청 우선순위화, 서버 푸시, HTTP 헤더 필드 압축 기능 등을 제공함. 
- HTTP/2의 데이터 계층 구조
	- 연결: 클라리언트와 서버를 잇는 단 1개의 실제 TCP 연결
	- 스트림: 하나의 연결망 안에 만들어진 가상의 양방향 연결. 각 요청/응답마다 고유한 스트림 번호 부여.
	- 메시지: HTTP 요청이나 응답의 논리적 단위
	- 프레임: HTTP/2의 가장 작은 최소 단위. 메시지는 여러 개의 프레임으로 쪼개져서 전송.
- 프레임 구조
	- Length
	- Type: 헤더, 데이터, 통제 신호에 대한 구분 정보
	- Flags: 프레임의 상태(END_STREAM 플래그 등)
	- Stream ID: 스트림 식별자
	- Payload: 실제 쪼개진 데이터
- Head of Line 블로킹 문제: TCP 연결을 하나만 사용하던 방식은 여러 개의 객체를 전송하는 데 병목을 발생시킨다.
- 프레이밍: HTTP/2는 각 메시지를 프레임으로 나누고, 이를 병렬로 전송한다. 이전에는 대형 객체가 앞에 있으면 소형 객체는 대형 객체의 전송이 끝나야 전송이 시작되었지만, 프레이밍 후에는 소형 객체에 해당하는 프레임이 먼저 도착해 조립될 수 있다. 
- 메시지 우선순위화: 개발자들이 요청의 상대적 우선순위를 조정할 수 있게 하여 애플리케이션 성능을 최적화할 수 있게 해준다. 
### HTTP/3
- HTTP/2의 한계
	- TCP의 한계 중 하나는 결국 유실된 패킷에 대해 확실한 도착을 보장하고, 이 때문에 병목이 발생할 수 있다는 것이다. 프레이밍한 데이터라도 어떤 패킷이 유실되는 순간 해당 연결은 유실된 패킷을 다시 받아오기 위해 전체 작업이 막힌다. (TCP Head-of-Line Blocking)
- QUIC
	- TCP 자체를 수정하는 대신, 구글이 UDP를 기반으로 새로운 규칙을 만든 것이 QUIC이다. 
	- 완벽한 독립 스트림: 데이터 하나가 유실되어도 전체가 멈추지 않음
	- 초고속 연결 설정: TLS1.3을 내장하여 3-way handshake 대신 더 빠른 연결 방식을 사용한다. (최초 연결과 암호화 설정을 동시에 전송.)
	- 연결 마이그레이션: Wi-Fi가 셀룰러로 전환되는 등의 상황에서 IP가 바뀌기 때문에 TCP가 다시 연결되는 대신 연결ID로 식별하여 IP가 바뀌더라도 연결ID가 같으면 새로운 연결을 개설하지 않음. 
## 2. 탐구 내용 (실무 / iOS 연결)
### URLSession이 사용하는 HTTP 헤더
```Swift
func sendURLSessionTask() {
    // 요청을 되돌려주는 테스트 서버 URL
    let url = URL(string: "https://httpbin.org/get")!
    // 헤더를 추가하지 않은 URLRequest
    let request = URLRequest(url: url)
    print(request.allHTTPHeaderFields ?? "No headers")
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("네트워크 에러: \(String(describing: error))")
            return
        }
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let headers = jsonObject["headers"] as [String: String] {

                print("🚀 URLSession 기본 헤더 🚀\n")

                for (key, value) in headers {
                    print("\(key): \(value)")
                }
            }
        } catch {
            print("JSON 파싱 에러")
        }
    }
    task.resume()
}
```
httpbin.org 사이트에 기본 요청 전송. 어떠한 헤더도 직접 추가한 것은 없음.
테스트 사이트는 받은 요청을 응답으로 보내주기 때문에 응답을 확인할 수 있음.
```
X-Amzn-Trace-Id: Root=1-69ce9d13-6519e39812b7f2e05055a8c2

Accept-Encoding: gzip, deflate, br

Accept-Language: ko-KR,ko;q=0.9

Host: httpbin.org

Accept: */*

User-Agent: Test/1 CFNetwork/3860.200.71 Darwin/25.3.0
```
위 결과에서 URLSession이 5가지 헤더를 기본적으로 추가하는 것을 확인 가능. 
- Host: HTTP/1.1에서 규격화된 규칙. 현대 서버가 여러 도메인을 동시에 호스팅하기 때문에 IP주소만으로 서비스를 찾지 못하는 것을 보충하는 정보. 
- Accept-Encoding: gzip, deflate, br(브로틀리) 압축 형식을 지정하여 트래픽 성능을 높힐 수 있는 설정을 추가. 대역폭 및 배터리 절약 가능. 
- Accept-Language: 언어 설정에 맞춘 다국어 처리 자동화.
- User-Agent: 서버가 통계 수집, 버그 대응을 용이하게 할 수 있다. 
- Accept: 데이터 포맷을 지정하는 헤더이며, 기본값은 모든 종류를 받을 수 있다는 와일드카드이다. 
예상치 못했던 것은 X-Amzn-Trace-Id라는 이름의 헤더였다. 이는 httpbin.org가 AWS 상에서 작동하며 추가된 헤더라고 한다. 아마존의 로드 밸런서가 분산 추적을 하기 위해 추가하는 ID이다.
```
GET /get HTTP/1.1

Host: httpbin.org

Accept: */*

Accept-Language: ko-KR,ko;q=0.9

Connection: keep-alive

Accept-Encoding: gzip, deflate, br

User-Agent: Test/1 CFNetwork/3860.200.71 Darwin/25.3.0
```
한편 Proxyman으로 캡쳐했을 떄는 Connection이라는 항목을 확인할 수 있었다. Proxyman에서만 해당 헤더가 관측된 이유는 두 가지로 추정된다. 
- Connection 헤더가 End-to-End 헤더가 아닌 Hop-by-Hob 헤더라고 한다. 목적 호스트까지 전달되는 것이 아니라 다음 노드까지만 전달되는 헤더인 것.
	- Hob-by-Hob 헤더 예시: Connection, Keep-Alive, Transfer-Encoding, Upgrade, Proxy-Authenticate, Proxy-Authorization, TE, Trailer 등
- HTTP/2에서는 connection 헤더를 사용하지 않는다. 단일 연결을 사용한 멀티플렉싱을 구현하기 위해서 애초에 연결을 끊을 일이 없기 때문.
### iOS Cookie
#### HTTPCookieStorage
iOS앱 내에서 발생하는 모든 HTTP 통신의 쿠키는 HTTPCookieStorage.shared라는 싱글톤 객체에서 관리됨. 별도의 설정을 하지 않으면 URLSession은 이곳에 쿠키를 저장하고 꺼내 쓴다.
#### URLSession 쿠키 제어
URLSessionConfiguration을 통해 쿠키가 동작하는 방식 결정.
- httpShouldSetCookies: 기본값 true. 서버 응답 헤더에 Set-Cookie가 있으면 자동으로 저장소에 넣고, 요청 시 자동으로 헤더에 붙임.
- httpCookieAcceptPolicy: 쿠키 수락 정책 설정. (모두 허용, 차단, 동일 도메인만 허용 등)
- httpCookieStorage: 기본은 .shared를 사용하지만 특정 세션을 위한 별도의 쿠키 저장소를 만들 수도 있음.
#### WKWebView와 동기화
네이티브 URLSession에서 사용하는 HTTPCookieStorage와 웹뷰가 사용하는 쿠키 저장소는 별도의 프로세스에서 돌아간다. 따라서 쿠키를 적용하고 싶다면 WKHTTPCookieStore를 사용하여 수동으로 복사해야 한다.
## 3. 의문 / 논점 

## 4. 참고 자료
