//
//  NetworkTestViewModel.swift
//  ip-port
//
//  Created by 이상유 on 2026-03-27.
//

import Combine
import UIKit
import Foundation
import Network

// MARK: - Models

enum TestTarget: String, CaseIterable, Identifiable {
    case localHTTP     = "로컬 서버 (HTTP)"
    case externalHTTP  = "외부 HTTP"
    case externalHTTPS = "외부 HTTPS"

    var id: String { rawValue }

    var url: URL {
        switch self {
        case .localHTTP:
            // 시뮬레이터: 127.0.0.1 동작 / 실기기: Mac의 LAN IP로 바꿔야 함
            // 실기기 테스트 시 아래 주석 해제 후 Mac IP 입력
            // return URL(string: "http://192.168.x.x:8080/regions?query=seoul&per_page=5")!
            return URL(string: "http://127.0.0.1:8080/regions?query=seoul&per_page=5")!
        case .externalHTTP:
            // httpbin.org 는 HTTP/HTTPS 모두 지원 — 안정적이고 응답 구조 동일
            // Info.plist에서 NSAllowsArbitraryLoads = true 없으면 ATS 차단
            return URL(string: "http://httpbin.org/get")!
        case .externalHTTPS:
            // 요청 내용을 그대로 돌려주는 httpbin — 헤더/IP 확인에 최적
            return URL(string: "https://httpbin.org/get")!
        }
    }

    /// 기본 Wireshark 필터 (IP 없이 포트만) — 요청 전 사전 필터링용
    var wiresharkFilter: String {
        switch self {
        case .localHTTP:
            return "tcp.port == 8080"
        case .externalHTTP:
            return "tcp.port == 80"
        case .externalHTTPS:
            // HTTP/3(QUIC=UDP) 가능성 포함
            return "tcp.port == 443 or udp.port == 443"
        }
    }
}

enum RequestStatus {
    case idle
    case loading
    case success(NetworkResult)
    case failure(NetworkError)
}

struct NetworkResult {
    let statusCode: Int
    let localIP: String
    let remoteIP: String
    let remotePort: Int
    let responseSnippet: String
    let duration: TimeInterval
    let connectionMetrics: ConnectionMetrics?   // nil이면 메트릭 수집 실패
}

enum NetworkError: LocalizedError {
    case atsBlocked(String)
    case connectionRefused
    case timeout
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .atsBlocked(let msg):
            return "🔒 ATS 차단: \(msg)"
        case .connectionRefused:
            return "❌ 연결 거부 (로컬 서버 실행 중인지 확인)"
        case .timeout:
            return "⏱ 타임아웃"
        case .unknown(let msg):
            return msg
        }
    }
}

// MARK: - Connection Metrics
// URLSessionTaskDelegate 의 didFinishCollecting 에서 수집한 실측값

struct ConnectionMetrics {
    var remoteIP: String         // 실제 연결된 IP (DNS 재조회 아님)
    var remotePort: Int
    var localIP: String
    var networkProtocol: String  // "http/1.1" | "h2" | "h3"
    var tlsVersion: String?      // "TLS 1.2" | "TLS 1.3" | nil(HTTP)
    var isReusedConnection: Bool // 커넥션 재사용 여부

    /// Wireshark 디스플레이 필터 — 실측 IP 기반이라 정확함
    var wiresharkFilter: String {
        let transportPort = remotePort
        let proto = networkProtocol
        if proto == "h3" {
            // HTTP/3 = QUIC = UDP
            return "ip.addr == \(remoteIP) && udp.port == \(transportPort)"
        } else {
            return "ip.addr == \(remoteIP) && tcp.port == \(transportPort)"
        }
    }

    var transportLayerNote: String {
        switch networkProtocol {
        case "h3":
            return "HTTP/3 (QUIC) — UDP \(remotePort) · tcp.port 필터로는 안 잡힘"
        case "h2":
            return "HTTP/2 — TCP \(remotePort)"
        case "http/1.1":
            return "HTTP/1.1 — TCP \(remotePort)"
        default:
            return networkProtocol
        }
    }
}

// MARK: - ViewModel

@MainActor
final class NetworkTestViewModel: ObservableObject {

    @Published var results: [TestTarget: RequestStatus] = {
        var dict = [TestTarget: RequestStatus]()
        TestTarget.allCases.forEach { dict[$0] = .idle }
        return dict
    }()

    @Published var deviceInfo = DeviceInfo()

    // MARK: - Public

    func runAll() {
        Task {
            await withTaskGroup(of: Void.self) { group in
                for target in TestTarget.allCases {
                    group.addTask { await self.run(target) }
                }
            }
        }
    }

    func run(_ target: TestTarget) async {
        results[target] = .loading

        let delegate = MetricsDelegate()
        let session  = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
        defer { session.invalidateAndCancel() }

        let request = makeRequest(for: target)
        let start   = Date()

        do {
            let (data, response) = try await session.data(for: request)
            let duration = Date().timeIntervalSince(start)

            guard let http = response as? HTTPURLResponse else {
                results[target] = .failure(.unknown("HTTPURLResponse 캐스팅 실패"))
                return
            }

            let metrics = await delegate.collectedMetrics
            let localIP = localIPAddress() ?? "알 수 없음"
            let snippet = String(data: data.prefix(300), encoding: .utf8)?
                            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "(바이너리)"

            results[target] = .success(NetworkResult(
                statusCode:      http.statusCode,
                localIP:         metrics?.localIP  ?? localIP,
                remoteIP:        metrics?.remoteIP ?? "알 수 없음",
                remotePort:      metrics?.remotePort ?? defaultPort(for: target),
                responseSnippet: snippet,
                duration:        duration,
                connectionMetrics: metrics
            ))

        } catch let error as URLError {
            results[target] = .failure(classify(error))
        } catch {
            results[target] = .failure(.unknown(error.localizedDescription))
        }
    }

    func reset() {
        TestTarget.allCases.forEach { results[$0] = .idle }
    }

    // MARK: - Private Helpers

    private func makeRequest(for target: TestTarget) -> URLRequest {
        var req = URLRequest(url: target.url, timeoutInterval: 10)
        req.httpMethod = "GET"
        req.setValue("NetworkTest/1.0 iOS-Study", forHTTPHeaderField: "User-Agent")
        return req
    }

    private func defaultPort(for target: TestTarget) -> Int {
        switch target {
        case .localHTTP:     return 8080
        case .externalHTTP:  return 80
        case .externalHTTPS: return 443
        }
    }

    private func classify(_ error: URLError) -> NetworkError {
        switch error.code {
        case .appTransportSecurityRequiresSecureConnection:
            return .atsBlocked(error.localizedDescription)
        case .cannotConnectToHost, .networkConnectionLost:
            return .connectionRefused
        case .timedOut:
            return .timeout
        default:
            if error.localizedDescription.lowercased().contains("app transport") ||
               error.localizedDescription.contains("-1022") {
                return .atsBlocked(error.localizedDescription)
            }
            return .unknown("[\(error.code.rawValue)] \(error.localizedDescription)")
        }
    }

    /// Wi-Fi 인터페이스(en0)에서 IPv4 주소 추출
    private func localIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while let current = ptr {
            let interface = current.pointee
            let family = interface.ifa_addr.pointee.sa_family
            if family == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr,
                                socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, 0, NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
            ptr = current.pointee.ifa_next
        }
        return address
    }
}

// MARK: - MetricsDelegate
// URLSessionTaskDelegate 로 실제 연결 메타데이터를 수집

final class MetricsDelegate: NSObject, URLSessionTaskDelegate {

    private var metrics: ConnectionMetrics?

    /// 비동기로 메트릭 수집 완료를 기다리기 위한 continuation
    private var continuation: CheckedContinuation<ConnectionMetrics?, Never>?
    private var taskFinished = false
    private var metricsReceived = false

    var collectedMetrics: ConnectionMetrics? {
        get async {
            if metrics != nil { return metrics }
            return await withCheckedContinuation { cont in
                self.continuation = cont
            }
        }
    }

    // 실제 연결에 사용된 IP, 포트, 프로토콜, TLS 버전 수집
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didFinishCollecting taskMetrics: URLSessionTaskMetrics) {

        // 트랜잭션 중 실제 새 TCP/UDP 연결이 맺어진 것만 사용
        // (재사용 커넥션이면 remoteAddress 가 nil 일 수 있음)
        let transaction = taskMetrics.transactionMetrics
            .first(where: { $0.remoteAddress != nil })
            ?? taskMetrics.transactionMetrics.last

        guard let tx = transaction else {
            resume(with: nil); return
        }

        let remoteIP   = tx.remoteAddress ?? "알 수 없음"
        let remotePort = tx.remotePort ?? 443
        let localIP    = tx.localAddress  ?? "알 수 없음"
        let proto      = tx.networkProtocolName ?? "알 수 없음"
        let tls        = tlsVersionString(from: tx)
        let reused     = tx.isReusedConnection

        resume(with: ConnectionMetrics(
            remoteIP:            remoteIP,
            remotePort:          remotePort,
            localIP:             localIP,
            networkProtocol:     proto,
            tlsVersion:          tls,
            isReusedConnection:  reused
        ))
    }

    private func resume(with m: ConnectionMetrics?) {
        metrics = m
        continuation?.resume(returning: m)
        continuation = nil
    }

    private func tlsVersionString(from tx: URLSessionTaskTransactionMetrics) -> String? {
        // negotiatedTLSProtocolVersion: tls_protocol_version_t (UInt16)
        // 0x0304 = TLS 1.3 / 0x0303 = TLS 1.2
        guard let ver = tx.negotiatedTLSProtocolVersion else { return nil }
        switch ver.rawValue {
        case 0x0304: return "TLS 1.3"
        case 0x0303: return "TLS 1.2"
        case 0x0302: return "TLS 1.1"
        default:     return String(format: "0x%04X", ver.rawValue)
        }
    }
}


// MARK: - Device Info

struct DeviceInfo {
    var model: String = UIDevice.current.model
    var systemVersion: String = UIDevice.current.systemVersion
    var isSimulator: Bool = {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }()
}
