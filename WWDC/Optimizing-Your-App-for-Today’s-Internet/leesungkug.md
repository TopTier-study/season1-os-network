## 1. 시청한 WWDC 영상
- **세션 제목**: Optimizing Your App for Today’s Internet (WWDC18, Session 714)
- **링크**: [WWDC Index - Session 714](https://nonstrict.eu/wwdcindex/wwdc2018/714/)

## 2. 내용 요약
- **세션 핵심 주제**

  인터넷은 여전히 느리고 불안정할 수 있다는 전제에서, 앱 코드만 잘 짜는 것보다 **현대 네트워크 기능을 제대로 활용하는 설계**가 중요하다는 내용을 담은 세션이었습니다.

- **주요 개념 / 기술 정리**
  1. **느린 네트워크를 기본값으로 테스트하기**
     - 개발 초반부터 `Network Link Conditioner`를 켜고 테스트해야 한다.
     - 성능 분석 도구로 `Wireshark`, `tcptrace`를 적극 활용한다.
  2. **기반 네트워크 기술(성능 + 복원력)**
     - `IPv6`는 실제 환경에서 IPv4보다 연결 설정/RTT가 유리한 사례가 많다.  
       (세션에서 인도 셀룰러 측정 예시: v6가 v4 대비 유의미하게 빠름)
     - `ECN`은 패킷 드롭 전에 혼잡 신호를 전달해 재전송 비용을 줄인다.  
       (Apple 플랫폼에서는 기본 활성화, 서버 지원 확인 필요)
     - `Multipath TCP`는 Wi-Fi -> 셀룰러 전환 같은 상황에서 연결 복원력에 도움을 준다.
     - `TCP Fast Open`은 초기 왕복 지연을 줄이는 데 유리하다.
     - `QUIC`은 당시(2018년) 표준화 진행 중인 차세대 전송 프로토콜로 소개되었다.
  3. **보안/이름해석 관련 변화**
     - `TLS 1.3`은 보안 강화와 함께 연결 설정 시간 단축 효과가 있다.  
       세션 당시(2018년)에는 곧 기본 활성화 예정이므로 호환성 사전 점검을 권장했다.
     - `Certificate Transparency`는 새 인증서의 공개 로그 기록을 강제해 불법 인증서 리스크를 줄인다.
     - DNS TTL이 짧을 때 생기는 지연 비용을 줄이기 위해,  
       **만료 캐시 즉시 사용 + 백그라운드 재조회**(옵트인) 전략을 소개했다.  
       응답이 바뀌면 비동기로 새 주소를 전달하며, `Happy Eyeballs`와 함께 쓰는 시나리오를 강조했다.
  4. **API 선택 가이드**
     - `SCNetworkReachability`로 사전 연결 가능 여부를 예측하는 패턴은 레이스 컨디션을 만들기 쉬워 지양.
     - 대신 `waitsForConnectivity`를 사용해, 연결 가능 시점에 시스템이 요청을 이어가게 한다.
     - HTTP/URL 기반 통신은 `URLSession`이 기본 선택이다.
     - 저수준 TCP 통신이 필요하면 BSD 소켓 래퍼보다 `Network.framework`를 우선 고려한다.
  5. **URLSession Best Practices**
     - **지연 시간 줄이기**
       - 서버 `HTTP/2` 활성화
       - `HTTP/2 Connection Coalescing` 활용(iOS 12, macOS Mojave 소개)
       - `URLSession` 객체를 남발하지 말고 재사용
     - **처리량 높이기**
       - 쿠키 domain/path 범위를 최소화하고, 불필요한 쿠키 삭제
       - 서버 압축(`Gzip`, `Brotli`) 활성화
     - **반응성 높이기**
       - 중요도 낮은 작업은 백그라운드 QoS에서 `task.resume()`
       - 필요한 경우 `networkServiceType = .responsiveData`를 신중히 사용
       - 오프라인 시 `waitsForConnectivity` + 대기 UI 전략 사용
     - **시스템 자원 효율**
       - 대용량 전송은 `Background Session` 활용
       - 캐시는 무조건 많이가 아니라, 재사용 가능 리소스 중심으로 제한
       - `willCacheResponse`, 서버 `Cache-Control`로 정책 제어

  6. **URLSession Best Practices (2026 기준 추가 포인트)**
     - **지연 시간 줄이기**
       - HTTP/3 지원 서버에서는 `URLSession`이 자동 협상하도록 두고, 서버가 HTTP/3 가능함이 확실하면 `URLRequest.assumesHTTP3Capable = true`로 초기 QUIC 레이싱 비용을 줄일 수 있음.
       - `HTTPShouldUsePipelining`은 최신 SDK에서 `HTTP/2`, `HTTP/3` 채택 권장과 함께 deprecated 되었으므로, 신규 최적화는 h2/h3 기준으로 설계하는 것이 맞음.
       - iOS 26+에서는 `URLSessionConfiguration.enablesEarlyData`(HTTP/3 0-RTT) 옵션이 추가되었고, 재전송(Replay) 리스크 때문에 안전한 GET/HEAD 위주로만 제한적으로 쓰는 것이 권장됨.
     - **처리량/네트워크 비용 제어**
       - 사용자 네트워크 비용을 고려해 `allowsExpensiveNetworkAccess`, `allowsConstrainedNetworkAccess`, `allowsUltraConstrainedNetworkAccess`를 요청 성격별로 다르게 적용.
       - 즉시성이 낮은 동기화/프리페치는 비싼 망이나 제약 망에서 지연 또는 생략 가능하도록 정책을 분리하는 편이 실무적으로 유리함.
     - **반응성 높이기**
       - `waitsForConnectivity = true`를 쓸 때는, 대기 중에는 `timeoutIntervalForRequest`가 적용되지 않고 `timeoutIntervalForResource`만 적용된다는 점을 같이 설계해야 함.
       - 사용자가 "멈췄다"고 느끼지 않게 하려면 `taskIsWaitingForConnectivity` 콜백 시점에 UI 상태(대기/재시도 안내)를 함께 노출하는 것이 좋음.
     - **시스템 자원/DNS 전략**
       - 보안 요구가 높은 요청은 `requiresDNSSECValidation`을 검토해 DNS 검증 강도를 높일 수 있음.
       - iOS 18+의 `allowsPersistentDNS`는 "네트워크가 바뀌어도 거의 변하지 않는 호스트"에 한해 신중히 사용하면 DNS 재조회 비용을 줄이는 데 도움됨.

- **내가 이해한 핵심 정리**
  - 네트워크 최적화는 "빠른 회선에서 잘 됨"이 아니라, **느린 회선에서도 안정적으로 동작하도록 기본 전략을 설계하는 것**이다.
  - URLSession은 단순 HTTP 호출 API가 아니라, 현대 네트워크 최적화를 얻는 가장 실용적인 진입점이다.
  - 연결 재사용(HTTP/2, coalescing, 적은 session 수)이 체감 성능에 미치는 영향이 매우 크다.

- **실무 체크리스트**
  1. 릴리즈 전이 아니라 개발 초기부터 `Network Link Conditioner` 프로파일로 상시 테스트하기
  2. 서버 `HTTP/2`, `IPv6`, `ECN`, 압축(Gzip/Brotli) 지원 상태 점검하기
  3. `URLSession` 인스턴스 수를 줄이고 연결 재사용 전략을 깨지 않기
  4. Reachability preflight 루프를 걷어내고 `waitsForConnectivity`로 전환하기
  5. 대용량 작업은 Background Session으로 분리하고, 캐시는 재사용 기준으로 엄격히 제한하기

- **2018 시점 -> 2026 관점 업데이트**
  
  해당 영상이 18년도 기준으로 설명하고 있어 현재는 어떻게 진행되고 있는지 추가로 정리해보았습니다.

  1. **QUIC / HTTP/3**
     - 2018: QUIC은 "표준화 진행 중" 기술로 소개됨.
     - 2026: QUIC은 `RFC 9000(2021)`, HTTP/3는 `RFC 9114(2022)`로 표준화 완료.  
       Apple도 WWDC21에서 iOS 15/macOS Monterey의 URLSession HTTP/3 기본 지원을 안내함.
  2. **TLS 1.3**
     - 2018: "곧 기본 활성화"를 대비해 사전 호환성 테스트를 권장.
     - 2026: TLS 1.3(`RFC 8446`)은 표준화 완료 후 폭넓게 사용되고 있으며,  
       앱/서버는 "지원 여부"보다 "호환성 예외를 줄이는 운영"이 더 중요한 단계로 이동.
  3. **Certificate Transparency(CT)**
     - 2018: Apple 플랫폼에서 신규 인증서 CT 검증 강제 예정 안내.
     - 2026: Apple의 CT 정책 문서가 계속 갱신되며(최신 공개본 2025-04-21),  
       공개 신뢰 TLS 인증서의 SCT 요건을 충족하지 않으면 연결 실패가 발생할 수 있음.
  4. **IPv6**
     - 2018: 성능/전환 관점의 권장사항 중심.
     - 2026: Apple은 App Store 제출 앱의 IPv6-only 네트워크 호환 요구를 유지하고 있으며,  
       URLSession/CFNetwork + 도메인 기반 연결 사용이 여전히 기본 권장 경로.
  5. **Reachability Preflight -> 연결 적응형 처리**
     - 2018: `SCNetworkReachability` 사전 점검 패턴 지양, `waitsForConnectivity` 권장.
     - 2026: 방향성은 동일하며, 경로 관찰은 `NWPathMonitor`(Network.framework)로 처리하고  
       실제 요청 성공/대기는 URLSession 정책(`waitsForConnectivity`)으로 맡기는 패턴이 일반적.
  6. **Multipath TCP**
     - 2018: 복원력 향상 기술로 소개(특히 네트워크 인터페이스 전환 시).
     - 2026: 프로토콜 자체는 `RFC 8684(2020)`로 표준화되었고,  
       실무에서는 네트워크/서버 정책에 따라 효과가 달라지므로 "가용 환경에서 선택적으로 활용"하는 성격이 강함.
  7. **DNS 지연 최적화 메시지의 현재 해석**
     - 2018: 짧은 TTL로 인한 지연을 줄이기 위해 stale DNS 응답 활용 + 병렬 조회를 소개.
     - 2026: 핵심 철학은 그대로이며, `Happy Eyeballs v2(RFC 8305)` 같은 병렬 연결 전략과 함께  
       "첫 연결을 늦추지 않으면서 최신 경로를 반영"하는 설계 원칙으로 받아들여짐.
