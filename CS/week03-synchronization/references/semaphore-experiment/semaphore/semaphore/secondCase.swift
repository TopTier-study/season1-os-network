//
//  secondCase.swift
//  semaphore
//
//  Created by 이상유 on 2026-03-12.
//

import Foundation
 
// ============================================================
// 🟢 해결 상황: withCheckedContinuation으로 올바르게 브릿징
// ============================================================
//
// 실행 방법: Xcode에서 macOS Command Line Tool 프로젝트 생성 후
// main.swift에 이 코드를 붙여넣고 실행하세요.
//
// ✅ 이 코드는 데드락 없이 정상적으로 완료됩니다.
// ============================================================
 
// MARK: - 해결책 1: withCheckedContinuation (콜백 → async 브릿징)
 
/// continuation을 사용하여 스레드를 블로킹하지 않는 (올바른) 함수
func fetchDataWithContinuation(id: Int) async -> String {
    print("  [Task \(id)] 🟡 네트워크 요청 시작...")
 
    let result: String = await withCheckedContinuation { continuation in
        // 비동기 작업을 시뮬레이션 (0.5초 딜레이)
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            let data = "Task \(id)의 응답 데이터"
            print("  [Task \(id)] 🟢 데이터 수신 완료, continuation.resume() 호출")
 
            // ✅ 스레드를 블로킹하지 않고 결과를 전달
            // await 지점에서 스레드는 양보(yield)되어 다른 Task가 사용 가능
            continuation.resume(returning: data)
        }
    }
    // ✅ resume이 호출되면 여기서부터 다시 실행됨
    //    이때 런타임이 사용 가능한 스레드를 할당해줌
 
    return result
}
 
// MARK: - 해결책 2: Actor를 활용한 동시 접근 제한
 
/// non-blocking 세마포어 역할을 하는 Actor
/// 동시 실행 수를 제한하면서도 스레드를 블로킹하지 않음
actor ConcurrencyLimiter {
    private let maxConcurrent: Int
    private var currentCount = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []
 
    init(maxConcurrent: Int) {
        self.maxConcurrent = maxConcurrent
    }
 
    func acquire() async {
        if currentCount < maxConcurrent {
            currentCount += 1
            return
        }
 
        // ✅ 스레드를 블로킹하지 않고 대기
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
 
    func release() {
        currentCount -= 1
        if !waiters.isEmpty {
            currentCount += 1
            let waiter = waiters.removeFirst()
            waiter.resume()
        }
    }
}
 
/// ConcurrencyLimiter를 사용하여 동시 요청 수를 제한하는 예시
func fetchDataWithLimiter(id: Int, limiter: ConcurrencyLimiter) async -> String {
    await limiter.acquire()
    defer { Task { await limiter.release() } }
 
    print("  [Task \(id)] 🟡 요청 시작 (동시 실행 제한 적용)")
 
    // 네트워크 요청 시뮬레이션
    let result: String = await withCheckedContinuation { continuation in
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            continuation.resume(returning: "Task \(id)의 응답 데이터")
        }
    }
 
    print("  [Task \(id)] 🟢 완료")
    return result
}
 
// MARK: - 데모 실행
 
func demonstrateSolution1() async {
    print("=" * 60)
    print("🟢 해결책 1: withCheckedContinuation")
    print("=" * 60)
    print()
    print("콜백 기반 API를 async로 브릿징할 때")
    print("세마포어 대신 continuation을 사용합니다.")
    print()
    print("💡 핵심 차이:")
    print("   semaphore.wait()  → 스레드를 블로킹 (점유한 채 멈춤)")
    print("   await continuation → 스레드를 양보 (다른 Task가 사용 가능)")
    print()
 
    let taskCount = 20
    print("📌 \(taskCount)개의 Task를 동시에 시작합니다...")
    print()
 
    let startTime = CFAbsoluteTimeGetCurrent()
 
    await withTaskGroup(of: String.self) { group in
        for i in 1...taskCount {
            group.addTask {
                await fetchDataWithContinuation(id: i)
            }
        }
 
        var completedCount = 0
        for await result in group {
            completedCount += 1
            print("  ✅ 완료 (\(completedCount)/\(taskCount)): \(result)")
        }
    }
 
    let elapsed = CFAbsoluteTimeGetCurrent() - startTime
    print()
    print("🎉 모든 작업이 데드락 없이 완료되었습니다!")
    print("⏱  소요 시간: \(String(format: "%.2f", elapsed))초")
    print("   (20개 작업이 동시에 실행되어 ~0.5초에 완료)")
}
 
func demonstrateSolution2() async {
    print()
    print("=" * 60)
    print("🟢 해결책 2: Actor 기반 동시 실행 제한 (non-blocking 세마포어)")
    print("=" * 60)
    print()
    print("세마포어의 동시 접근 제한 기능이 필요할 때,")
    print("Actor + continuation으로 non-blocking하게 구현합니다.")
    print()
    print("📌 동시 실행 수를 3개로 제한하여 10개의 Task를 실행합니다...")
    print()
 
    let limiter = ConcurrencyLimiter(maxConcurrent: 3)
    let taskCount = 10
    let startTime = CFAbsoluteTimeGetCurrent()
 
    await withTaskGroup(of: String.self) { group in
        for i in 1...taskCount {
            group.addTask {
                await fetchDataWithLimiter(id: i, limiter: limiter)
            }
        }
 
        var completedCount = 0
        for await result in group {
            completedCount += 1
            print("  ✅ 완료 (\(completedCount)/\(taskCount)): \(result)")
        }
    }
 
    let elapsed = CFAbsoluteTimeGetCurrent() - startTime
    print()
    print("🎉 모든 작업이 데드락 없이 완료되었습니다!")
    print("⏱  소요 시간: \(String(format: "%.2f", elapsed))초")
    print("   (동시 3개씩 실행되어 ~2초에 완료)")
}
 
func demonstrateComparison() async {
    print()
    print("=" * 60)
    print("📊 정리: 세마포어 vs Continuation 비교")
    print("=" * 60)
    print()
    print("┌─────────────────────┬──────────────────┬──────────────────┐")
    print("│                     │ DispatchSemaphore│ Continuation     │")
    print("├─────────────────────┼──────────────────┼──────────────────┤")
    print("│ 스레드 블로킹       │ ✗ 블로킹함       │ ✓ 양보함         │")
    print("│ async 컨텍스트 안전 │ ✗ 데드락 위험    │ ✓ 안전           │")
    print("│ cooperative pool    │ ✗ 스레드 소진    │ ✓ 스레드 재활용  │")
    print("│ GCD에서 사용        │ ✓ 동작함         │ - (불필요)       │")
    print("│ 에러 전달           │ ✗ 불가           │ ✓ throwing 가능  │")
    print("└─────────────────────┴──────────────────┴──────────────────┘")
    print()
    print("💡 핵심 원칙:")
    print("   async 컨텍스트에서는 절대 스레드를 블로킹하지 마세요.")
    print("   - 콜백 → async 변환: withCheckedContinuation 사용")
    print("   - 동시 접근 제한: Actor 또는 AsyncStream 활용")
    print("   - 상호 배제(mutex): Actor 사용")
}
