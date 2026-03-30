//
//  main.swift
//  semaphore
//
//  Created by 이상유 on 2026-03-12.
//

import Foundation

// MARK: -  문제 상황 실행
print()
print("⚠️  이 데모는 의도적으로 데드락을 발생시킵니다.")
print("    프로그램이 멈추면 Ctrl+C로 종료하세요.")
print()
 
// async 진입점
Task {
    await demonstrateDeadlock()
    exit(0)
}
 
// RunLoop 유지
RunLoop.main.run()

// MARK: - 해결 상황 실행
//Task {
//    await demonstrateSolution1()
//    await demonstrateSolution2()
//    await demonstrateComparison()
//    exit(0)
//}
// 
//// RunLoop 유지
//RunLoop.main.run()
