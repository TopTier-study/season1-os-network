//
//  main.swift
//  DeadlockTest
//
//  Created by 지연 on 3/19/26.
//

import Foundation

// MARK: - Serial queue

/// 시리얼 큐에서 발생하는 Deadlock
//let serialQueue = DispatchQueue(label: "serial.queue")
//
//serialQueue.sync {
//    print("1")
//
//    serialQueue.sync {
//        print("2")
//    }
//
//    print("3")
//}

/// 메인 큐에서 발생하는 Deadlock
/// 1) 메인 스레드 -> Deadlock 발생
//DispatchQueue.main.sync {
//    print("main deadlock")
//}

/// 2) 백그라운드 스레드 -> 정상 실행
//DispatchQueue.global().async {
//    print("background start")
//
//    DispatchQueue.main.sync {
//        print("run on main")
//    }
//
//    print("background end")
//}
//
//RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))


// MARK: - Concurrent queue

/// concurrent queue에서 발생하는 Deadlock
/// 1) barrior + sync 재진입
//let queue = DispatchQueue(label: "concurrent.queue", attributes: .concurrent)
//
//queue.async(flags: .barrier) {
//    print("barrier start")
//
//    queue.sync {
//        print("inner sync")
//    }
//
//    print("barrier end")
//}
//
//RunLoop.main.run(until: Date(timeIntervalSinceNow: 3))

/// 2) dispatchGroup.wait
let queue = DispatchQueue(label: "concurrent.queue", attributes: .concurrent)
let group = DispatchGroup()

queue.async(flags: .barrier) {
    print("outer start")

    group.enter()

    queue.sync {
        print("inner task")
        group.leave()
    }

    group.wait()
    print("outer end")
}

RunLoop.main.run(until: Date(timeIntervalSinceNow: 3))
