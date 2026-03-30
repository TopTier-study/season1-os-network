//
//  NetworkTestView.swift
//  ip-port
//
//  Created by 이상유 on 2026-03-27.
//

import Combine
import SwiftUI

// MARK: - Root View

struct NetworkTestView: View {
    @StateObject private var vm = NetworkTestViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    deviceBanner
                    rviGuideSection
                    controlButtons
                    ForEach(TestTarget.allCases) { target in
                        TestResultCard(target: target, status: vm.results[target] ?? .idle)
                    }
                }
                .padding()
            }
            .navigationTitle("Network Inspector")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Subviews

    private var deviceBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: vm.deviceInfo.isSimulator ? "laptopcomputer" : "iphone")
                .font(.title2)
                .foregroundStyle(vm.deviceInfo.isSimulator ? .orange : .green)
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.deviceInfo.isSimulator ? "시뮬레이터 실행 중" : "실기기 실행 중")
                    .font(.headline)
                Text("\(vm.deviceInfo.model) · iOS \(vm.deviceInfo.systemVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Circle()
                .fill(vm.deviceInfo.isSimulator ? .orange : .green)
                .frame(width: 10, height: 10)
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    /// 실기기일 때 RVI 설정 가이드 노출
    @ViewBuilder
    private var rviGuideSection: some View {
        if !vm.deviceInfo.isSimulator {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Mac 터미널에서 UDID 확인")
                        .font(.caption.bold())
                    CodeBlock("xcrun xctrace list devices")
                    Text("2. RVI 인터페이스 생성")
                        .font(.caption.bold())
                    CodeBlock("rvictl -s [UDID]")
                    Text("3. Wireshark에서 rvi0 인터페이스 선택")
                        .font(.caption.bold())
                    Text("4. 종료 시: rvictl -x [UDID]")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Divider()

                    Text("⚠️ 로컬 서버 주의")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                    Text("실기기에서 127.0.0.1은 iPhone 자신을 가리킵니다.\nViewModel의 localHTTP URL을 Mac의 LAN IP로 변경하세요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            } label: {
                Label("RVI 설정 가이드", systemImage: "network")
                    .font(.subheadline.bold())
            }
            .padding()
            .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 12) {
            Button {
                vm.runAll()
            } label: {
                Label("전체 요청 실행", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)

            Button {
                vm.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Test Result Card

struct TestResultCard: View {
    let target: TestTarget
    let status: RequestStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(target.rawValue)
                        .font(.headline)
                    Text(target.url.absoluteString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                statusBadge
            }
            .padding()
            .background(headerBackground)

            Divider()

            // Body
            Group {
                switch status {
                case .idle:
                    idleView
                case .loading:
                    loadingView
                case .success(let result):
                    successView(result)
                case .failure(let error):
                    failureView(error)
                }
            }
            .padding()

            // Wireshark filter hint
            wiresharkHint
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
    }

    // MARK: Header helpers

    private var headerBackground: Color {
        switch status {
        case .idle:      return .gray.opacity(0.06)
        case .loading:   return .blue.opacity(0.06)
        case .success:   return .green.opacity(0.06)
        case .failure:   return .red.opacity(0.06)
        }
    }

    private var statusBadge: some View {
        Group {
            switch status {
            case .idle:
                Text("대기")
                    .badgeStyle(color: .gray)
            case .loading:
                HStack(spacing: 4) {
                    ProgressView().scaleEffect(0.7)
                    Text("요청 중")
                }
                .badgeStyle(color: .blue)
            case .success(let r):
                Text("HTTP \(r.statusCode)")
                    .badgeStyle(color: r.statusCode < 300 ? .green : .orange)
            case .failure:
                Text("실패")
                    .badgeStyle(color: .red)
            }
        }
    }

    // MARK: Body helpers

    private var idleView: some View {
        Text("위 버튼으로 요청을 실행하세요")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var loadingView: some View {
        HStack {
            ProgressView()
            Text("연결 중…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func successView(_ r: NetworkResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // IP / Port 정보 — 학습의 핵심
            Group {
                InfoRow(icon: "iphone.and.arrow.forward",
                        label: "내 로컬 IP (en0)",
                        value: r.localIP,
                        note: "이 기기가 LAN에서 사용하는 사설 IP")
                InfoRow(icon: "server.rack",
                        label: "원격 IP",
                        value: r.remoteIP,
                        note: "DNS가 반환한 목적지 공인 IP")
                InfoRow(icon: "number",
                        label: "원격 포트",
                        value: "\(r.remotePort)",
                        note: portNote(r.remotePort))
                InfoRow(icon: "clock",
                        label: "응답 시간",
                        value: String(format: "%.0f ms", r.duration * 1000))
            }

            Divider()

            // 응답 미리보기
            Text("응답 미리보기")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(r.responseSnippet)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func failureView(_ error: NetworkError) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(error.errorDescription ?? "알 수 없는 오류")
                .font(.callout)
                .foregroundStyle(.red)

            // ATS 차단 시 해결 방법 안내
            if case .atsBlocked = error {
                atsGuide
            }
        }
    }

    private var atsGuide: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ATS 해결 방법")
                .font(.caption.bold())
            Text("Info.plist에 아래 키 추가 (테스트용, 배포 시 제거):")
                .font(.caption)
                .foregroundStyle(.secondary)
            CodeBlock("""
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
""")
        }
        .padding(10)
        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    // Wireshark 필터 힌트
    private var wiresharkHint: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                Text("Wireshark 디스플레이 필터")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 6) {
                Text(interfaceLabel)
                    .font(.system(.caption2, design: .monospaced))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
                    .foregroundStyle(.orange)
                Text(target.wiresharkFilter)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.blue)
                Spacer()
                CopyButton(text: target.wiresharkFilter)
            }
            Text(interfaceNote)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.blue.opacity(0.04))
    }

    private var interfaceLabel: String {
        switch target {
        case .localHTTP: return "lo0"
        case .externalHTTP, .externalHTTPS: return "en0 / rvi0"
        }
    }

    private var interfaceNote: String {
        switch target {
        case .localHTTP:
            return "127.0.0.1은 루프백 → 시뮬레이터에서 인터페이스를 lo0으로 바꿔야 잡힘"
        case .externalHTTP:
            return "시뮬레이터: en0 | 실기기: rvi0 · 요청 성공 후 ip.addr == <원격IP> && tcp.port == 80 으로 좁힐 수 있음"
        case .externalHTTPS:
            return "시뮬레이터: en0 | 실기기: rvi0 · TLS라 내용은 암호화, ClientHello/ServerHello만 관찰 가능"
        }
    }

    private func portNote(_ port: Int) -> String {
        switch port {
        case 80:   return "Well-Known Port — HTTP"
        case 443:  return "Well-Known Port — HTTPS"
        case 8080: return "등록된 포트 — 개발 서버"
        default:   return "포트 범위: \(portRange(port))"
        }
    }

    private func portRange(_ port: Int) -> String {
        switch port {
        case 0...1023:     return "Well-Known (0-1023)"
        case 1024...49151: return "등록된 포트 (1024-49151)"
        default:           return "동적/사설 포트 (49152-65535)"
        }
    }
}

// MARK: - Reusable Components

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    var note: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .frame(width: 16)
                .foregroundStyle(.blue)
                .font(.caption)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.callout, design: .monospaced).bold())
                if let note {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

struct CodeBlock: View {
    let code: String
    init(_ code: String) { self.code = code }

    var body: some View {
        Text(code)
            .font(.system(.caption2, design: .monospaced))
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
    }
}

struct CopyButton: View {
    let text: String
    @State private var copied = false

    var body: some View {
        Button {
            UIPasteboard.general.string = text
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.caption2)
                .foregroundStyle(copied ? .green : .blue)
        }
    }
}

// MARK: - Badge ViewModifier

struct BadgeModifier: ViewModifier {
    let color: Color
    func body(content: Content) -> some View {
        content
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

extension View {
    func badgeStyle(color: Color) -> some View {
        modifier(BadgeModifier(color: color))
    }
}

// MARK: - Preview

#Preview {
    NetworkTestView()
}
