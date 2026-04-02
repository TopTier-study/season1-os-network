import Network

let client = TCPClient()
client.start()

final class TCPClient: @unchecked Sendable {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "tcp-client")
    
    func start() {
        let host = NWEndpoint.Host("192.168.45.214")
        let port = NWEndpoint.Port(integerLiteral: 9999)
        
        connection = NWConnection(host: host, port: port, using: .tcp)
        
        connection?.stateUpdateHandler = { [self] state in
            switch state {
            case .setup:
                print("⬜ .setup")
            case .preparing:
                print("🟧 .preparing — 3-way handshake 진행 중")
            case .ready:
                print("🟩 .ready — ESTABLISHED")
                self.sendThenReceiveThenDisconnect()
            case .waiting(let error):
                print("🟡 .waiting: \(error)")
            case .failed(let error):
                print("🔴 .failed: \(error)")
            case .cancelled:
                print("⬛ .cancelled — CLOSED")
            @unknown default:
                break
            }
        }
        
        connection?.start(queue: queue)
    }
    
    private func sendThenReceiveThenDisconnect() {
        let data = "hello".data(using: .utf8)!
        
        connection?.send(content: data, completion: .contentProcessed { [self] error in
            if let error {
                print("송신 에러: \(error)")
                return
            }
            print("송신 완료: hello")
            
            self.connection?.receive(minimumIncompleteLength: 1,
                                     maximumLength: 1024) { [self] data, _, _, error in
                if let data, let text = String(data: data, encoding: .utf8) {
                    print("수신: \(text)")
                }
                if let error {
                    print("수신 에러: \(error)")
                }
                
                self.queue.asyncAfter(deadline: .now() + 1) { [self] in
                    print("🔵 cancel() 호출 — FIN 전송 시작")
                    self.connection?.cancel()
                }
            }
        })
    }
}