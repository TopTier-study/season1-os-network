# 네트워크 Layer 구조
### 학습 키워드
- OSI 7계층
- TCP/IP 4계층 모델
- TCP/IP 5계층 모델
## 1. 핵심 개념
### 계층화 이유
- 캡슐화: 크고 복잡한 시스템의 특정 부분을 논의할 수 있게 해준다. 계층 내의 일은 계층 내에서 해결 가능하다.
- 대체 가능성: 특정 계층의 서비스 구현을 변경하기 용이하다. 
예) 클린 아키텍쳐의 끝단에 해당하는 프레젠테이션 레이어를 변경하면 같은 도메인 모델에 대해 다른 방식으로 화면을 그릴 수 있었다.
### OSI 7계층이란?
국제표준화기구(ISO)가 개발한 네트워크 통신 과정을 7단계로 표준화한 모델.
### OSI 7계층 요약
1. 물리 계층(Physical Layer)
	- 0과 1의 디지털 데이터를 전기 신호나 빛의 신호로 바꿔 실제 랜선이나 전파를 통해 전달. 
2. 데이터 링크 계층(Data Link Layer)
	- 기기에 연결돤 다음 기기(노드)까지 물리적인 주소(MAC)를 사용해 전달. '스위치' 필요.
3. 네트워크 계층(Network Layer)
	- 수많은 라우터 중에서 가장 빠른 길을 찾아 목적 기기의 IP 주소로 패킷을 전송. '라우터' 필요.
4. 전송 계층(Transport Layer)
	- 데이터가 유실되지 않고 도착했는지 검사. TCP, UDP 프로토콜 등. 
5. 세션 계층(Session Layer)
	- 통신하는 양쪽 기기의 연결을 확립, 끈허지면 복구 등. API, 소켓.
6. 표현 계층(Presentation Layer)
	- 기기마다 다른 데이터 표현 방식을 통일(인코딩)하고, 보안을 위해 데이터를 암호화하거나 용량을 압축. JPEG, MPEG 처리 등.
7. 응용 계층(Application Layer)
	- 사용자가 사용하는 앱이 통신하는 계층. HTTP, SMTP(이메일), FTP(파일 전송) 등.
### TCP/IP 5계층 모델
1. 물리 계층
	- 0과 1 비트 단위를 실제 물리 매체를 통해 전송한다. 
2. 데이터 링크 계층
	- Node to Node, Hop by Hop 전달(다음 기기까지 전달)
	- MAC 프로토콜을 사용한다.
	- 일부 오류가 많은 연결에서는 신뢰적 전달 서비스를 적용할 수 있다.
	- 오류 검출과 정정을 수행할 수 있다. 
3. 네트워크 계층
	- 호스트 사이의 논리적 통신을 제공한다.
	- 종단 시스템 간 전달을 위해서 경로상의 다른 라우터를 거치며, 이 경로를 결정하는 행위가 라우팅, 알고리즘이 라우팅 알고리즘이다. 각 라우터에서는 포워딩 테이블을 확인해 목적지로 넘긴다. 라우팅 알고리즘은 각각의 모든 라우터에서 실행된다. 
4. 전송 계층
	- 애플리케이션 프로세스간의 논리적 통신을 제공한다. 라우터가 아닌 종단 시스템에 구성된다. 
	- 애플리케이션 계층은 전송 계층의 reliable data transfer한 프로토콜을 사용하거나, 그렇지 않은 프로토콜을 사용하여 loss-tolerant application을 만들 수 있다. 
	- 인터넷의 경우 TCP/UDP 프로토콜을 제공한다.
5. 애플리케이션 계층
	- 프로세스간 네트워크 애플리케이션의 동작을 정의.
	- 애플리케이션은 네트워크 기능을 사용하되, 네트워크 코어 장비에서 실행되는 소프트웨어까지 작성할 필요 없다. 
	- 프로세스와 전송 계층 사이의 인터페이스가 '소켓'이다. 거의 모든 네트워크는 결국 소켓을 거쳐 작동한다.(Kernel Bypass 등은 이것에서 예외인 극단적인 기술이다.)
	- 네트워크에서 호스트 주소가 IP라면, 호스트 내에서 프로세스를 식별하기 위한 주소로 포트 번호가 사용된다.
	- HTTP, SMTP, DNS 등
### TCP/IP 4계층 모델
1. 네트워크 접속(Network Access): 하드웨어, 랜선, MAC 주소
2. 인터넷(Internet): IP
3. 전송(Transport): 목적지 프로세스 찾기, TCP/UDP
4. 응용(Application)
## 2. 탐구 내용 (실무 / iOS 연결)
### 3개 계층 모델 비교
#### 매핑 관계?
위 3개 모델의 각 계층을 보았을 때 유사한 부분을 많이 볼 수 있었다. 특히 5계층 모델과 7계층 모델을 비교하였을 때는 계층의 이름이 모두 대응되는 것이 있어 같은 역할을 하는 것으로 보인다. 
- 4계층 모델 vs 7계층 모델
	- Application = L5 + L6 + L7
	- Transport = L4
	- Internet = L3
	- Network Access = L1 + L2
- 5계층 모델 vs 7계층 모델
	- Application = L5 + L6 + L7
	- Transport = L4
	- Network = L3
	- Data Link = L2
	- Physical = L1
대략 위의 정리와 같은 관계를 갖는다. 
하지만 말 그대로 대략일 뿐, 실제로 서로가 완벽하게 대응하는 관계는 아니다. 이는 등장 배경에 대한 내용이 있으면 이해가 편하다.
#### 약간의 역사
1970년대 미국 국방성(DoD)에서 인터넷의 시초인 '알파넷'이 등장할 때 학자들이 네트워크를 4개 계층으로 나누어 정의했다. 이것에 TCP/IP 4계층 모델, 또는 DoD 모델이다.

한편 OSI 7계층 모델은 학자들이 이론적으로 깔끔한 Layer를 만들기 위해 구성한 모델이다. 하지만 OSI 모델이 등장하기 전에 TCP/IP 모델이 시장을 장악하고, 7계층 모델은 학문적으로만 남겨지게 된다.

따라서 TCP/IP 모델은 실전성을 띄게 된다. 다만 기존 4계층 모델은 Application에서 3개 레이어를, Network Access에서 2개 레이어를 뭉개고 있는 것에서 알 수 있겠지만, L3, L4에만 관심을 갖는 모델이었다. 
Application 레이어를 통합한 것은 L5의 역할인 연결 세션 관리나 L6에서 관리하는 압축, 암호화는 서비스마다 다르기 떄문에 OS나 네트워크 시스템이 관리하는 것이 아니라 개발자가 관리할 영역이라는 TCP/IP의 철학에 기본적으로 부합한다.

하지만 Network Access 레이어는 초기와 다르게 기술의 발전에 따라 Layer를 구분할 필요성이 생겼고, 현대의 학자들이 OSI 7계층에 있던 하위 2계층을 가져와 TCP/IP모델에 이식했다. 따라서 TCP/IP 5계층 모델은 일부는 TCP/IP 4계층, 일부는 OSI 7계층 모델을 따르는 하이브리드 모델이 되었고, 가장 실전성있는 모델로 알려진다.
### URLSession 실행
```
func sendPresentationDemoRequest() {

    guard let url = URL(string: "https://httpbin.org/get") else { return }
    var request = URLRequest(url: url)

    request.httpMethod = "GET"
    request.addValue("*/*", forHTTPHeaderField: "Accept")
    request.addValue("deflate, gzip", forHTTPHeaderField: "Accept-Encoding")
    request.addValue("URLSession_Test", forHTTPHeaderField: "X-Project-Name")
    
    Task {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as HTTPURLResponse {
                print("✅ Status Code: \(httpResponse.statusCode)")
            }

            if let stringData = String(data: data, encoding: .utf8) {
                print("✅ Response Body:\n\(stringData)")
            }
        } catch {
            print("❌ Error: \(error)")
        }
    }
}
```
위는 임의로 AI를 이용해 생성한 URSession 코드이다. 테스트용 공개 API를 사용하여 간단한 요청을 보내는 코드이다. 
```HTTP
GET /get HTTP/1.1

Host: httpbin.org

X-Project-Name: URLSession_Test

Accept: */*

User-Agent: Test/1 CFNetwork/3860.200.71 Darwin/25.3.0

Accept-Language: ko-KR,ko;q=0.9

Accept-Encoding: deflate, gzip

Connection: keep-alive
```
Proxyman앱을 이용하여 발송되는 요청의 Raw값을 읽은 것이다. Accept, Accept-Encoding, X-Project-Name(커스텀 헤더)은 코드에서 직접 추가한 것이지만, 이외의 헤더는 기기의 정보를 읽어 HTTP 통신 규약에 맞게 URLSession에서 생성한 모습이다.

이러한 코드는 어플리케이션 계층에서 발생하는 일이며 이 계층에서 다루는 데이터에 대해 해석을 위해 헤더(여기서는 HTTP 헤더)를 붙이는 모습이다. 

<img width="1744" height="1390" alt="image" src="https://github.com/user-attachments/assets/657f03c4-eeb2-4600-8c54-435f0f130dfa" />

위 이미지는 같은 코드를 Wireshark를 이용해 관측한 결과이다. 
- Application Layer
	- Hypertext Transfer Protocol을 열어보면 위에서 관측했던 URLSession 코드의 Raw값을 확인할 수 있다. (하단에서도 확인 가능)
- Transport Layer
	- Transmission Control Protocol에서 확인할 수 있다. TCP/IP스택에서 작성한 TCP 헤더이다. 포트 주소 등이 적힌다. 하단에 하이라이트된 부분이 HTTP 기본 포트인 80번(16진수 50)으로 세팅된 모습이다.
- Network Layer
	- Internet Protocol Version 4, 즉 IPv4에 맞는 IP 주소를 헤더로 할당하고 있다. 
- Data Link Layer
	- Ethernet II... 에서 확인할 수 있으며 MAC 주소가 헤더로 들어간다.
- Physical Layer
	- Frame... 에서 확인할 수 있으며 하드웨어 단의 정보를 확인할 수 있다. 헤더는 확인되지 않았다.
Wireshark에서는 TCP/IP 5계층 모델에 따른 네트워크 구조를 확인할 수 있었다. 또한 각 레이어에서는 자신의 목적에 맞는 헤더를 붙이고, 상위 레이어의 헤더를 포함한 데이터를 묶어서 세그먼트로 다루고 있다.
### 계층이 명확하지 않은 경우
#### 계층 모델에서 보안
TLS(Transport Layer Security)는 인터넷상에서 컴퓨터 네트워크 통신 보안을 제공하는 암호화 프로토콜이다. 데이터를 암호화하여 제3자가 내용을 훔쳐보거나 위조할 수 없도록 보호한다. SSL(Secure Sockets Layer)의 후속 버전이다.

그렇다면 이러한 암호화는 어떤 Layer에 속할까?

OSI 7계층의 설명에서는 보안을 담당하기 떄문에 Layer 6, 세션을 맺는 Layer 5에서 이루어진다. 하지만 TCP/IP 모델에서는 이 계층을 따로 두지 않았는데, 대신 Transport Layer에서 TCP로 연결을 맺는 등의 동작 후, TLS가 암호화 키를 교환하고 암호화를 실행한다. 
#### 로드밸런서
Load Balancer는 현대의 트래픽 분산 장비이다. 서버가 여러개일 경우 한 서버에 부하가 몰리지 않도록 분산해주는 역할을 한다.
목적지를 정하는 라우터의 역할을 하기 때문에 Layer 3에 속하는 것으로 보이지만 실제로는 더 많은 정보를 확인한다.
- L4 로드밸런서: 전송 계층의 IP주소, 포트 번호 등의 정보를 통해 트래픽을 여러 서버로 나눠준다.
- L7 로드밸런서: 응용 계층에 포함된 정보까지 확인한다. 데이터의 종류까지 확인하여 처리를 할 수 있다. 예시로 사진 관련된 API임을 확인하여 이미지 전용 서버로 요청을 보낸다.
#### NWPathMonitor
NWPathMonitor는 iOS에서 네트워크의 상태를 감지할 수 있는 도구이다. WiFi, Cellular 등을 따로 지정해서 감시할 수 있다. 

계층 구조에서의 철학은 상위 계층은 하위 계층의 동작을 추상화하고, 그 값만을 가지고 동작하는 것이기 때문에 어떻게 동작하든 관심이 없어야 하지만 모바일에서 와이파이와 셀룰러 데이터를 전환하는 과정에서 일어나는 네트워크 단절 때문에 버그가 일어나는 등 하위 계층의 정보가 필요할 때가 있다. NWPathMonitor는 이렇듯 계층을 깨고, 하위 레이어에서 일어나는 일에 대한 정보를 관찰하는 도구이다.
## 3. 의문 / 논점
- 각 레이어에서는 다음 레이어에 어떤 인터페이스를 요구할까?
## 4. 참고 자료
- https://aws.amazon.com/ko/what-is/osi-model/
- 컴퓨터 네트워킹 하향식 접근 8판
