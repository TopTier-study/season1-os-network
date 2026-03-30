//
//  firstCase.swift
//  semaphore
//
//  Created by 이상유 on 2026-03-12.
//

import Foundation
 
// ============================================================
// 🔴 문제 상황: async 컨텍스트에서 DispatchSemaphore 사용 시 데드락
// ============================================================
//
// 실행 방법: Xcode에서 macOS Command Line Tool 프로젝트 생성 후
// main.swift에 이 코드를 붙여넣고 실행하세요.
//
// ⚠️ 이 코드는 의도적으로 데드락을 발생시킵니다.
//    약 5초 후 타임아웃으로 종료됩니다.
// ============================================================
 
/// 세마포어로 비동기 작업을 동기화하는 (잘못된) 함수
func fetchDataWithSemaphore(id: Int) async -> String {
    let semaphore = DispatchSemaphore(value: 0)
    var result = ""
 
    print("  [Task \(id)] 🟡 네트워크 요청 시작...")
 
    // 비동기 작업을 시뮬레이션 (0.5초 딜레이)
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
        result = "Task \(id)의 응답 데이터"
        print("  [Task \(id)] 🟢 데이터 수신 완료, signal() 호출")
        semaphore.signal()
    }
 
    // ❌ 핵심 문제: cooperative thread pool의 스레드를 블로킹!
    // Swift Concurrency의 스레드 풀은 코어 수만큼만 스레드를 가짐.
    // 모든 스레드가 여기서 wait()에 걸리면,
    // signal()을 호출할 DispatchQueue.global()의 블록도
    // 실행될 스레드를 얻지 못할 수 있음 → 데드락
    semaphore.wait()
 
    return result
}
 
/// 여러 Task를 동시에 실행하여 데드락을 유발하는 함수
func demonstrateDeadlock() async {
    print("=" * 60)
    print("🔴 문제 상황: DispatchSemaphore + async 컨텍스트")
    print("=" * 60)
    print()
    print("cooperative thread pool의 스레드를 모두 블로킹하여")
    print("데드락을 유발합니다.")
    print()
    print("💡 Swift Concurrency의 thread pool 크기 ≈ CPU 코어 수")
    print("   모든 스레드가 semaphore.wait()에 걸리면 signal()을")
    print("   실행할 스레드가 남지 않습니다.")
    print()
 
    let taskCount = 20  // 코어 수보다 많은 Task를 생성
    print("📌 \(taskCount)개의 Task를 동시에 시작합니다...")
    print("   (5초 후 타임아웃으로 강제 종료됩니다)")
    print()
 
    // 타임아웃 설정 (데드락 시 프로그램이 멈추므로)
    let timeoutTask = Task {
        try await Task.sleep(nanoseconds: 5_000_000_000)
        print()
        print("⏰ === 타임아웃! ===")
        print("   5초가 지났지만 작업이 완료되지 않았습니다.")
        print("   이것이 바로 데드락 상황입니다.")
        print()
        print("🔍 원인 분석:")
        print("   1. 모든 cooperative 스레드가 semaphore.wait()에서 블로킹됨")
        print("   2. signal()을 호출할 블록이 실행될 스레드가 부족함")
        print("   3. wait()는 signal()을 기다리고, signal()은 스레드를 기다림 → 데드락")
        print()
        print("💡 해결 방법: SemaphoreSolutionDemo.swift를 실행해보세요!")
        exit(1)
    }
 
    // 여러 Task를 동시에 생성
    await withTaskGroup(of: String.self) { group in
        for i in 1...taskCount {
            group.addTask {
                await fetchDataWithSemaphore(id: i)
            }
        }
 
        var completedCount = 0
        for await result in group {
            completedCount += 1
            print("  ✅ 완료 (\(completedCount)/\(taskCount)): \(result)")
        }
 
        timeoutTask.cancel()
        print()
        print("🎉 모든 작업 완료! (여기까지 도달하면 데드락이 발생하지 않은 것)")
    }
}
