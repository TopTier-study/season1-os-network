////
////  main.swift
////  ThroughputTest
////
////  Created by 지연 on 3/6/26.
////

import Foundation

@inline(never)
func heavyWork(_ seed: Int, loops: Int) -> UInt64 {
    var x = UInt64(seed) &* 2862933555777941757 &+ 3037000493
    for _ in 0..<loops {
        x ^= x &<< 13
        x ^= x &>> 7
        x ^= x &<< 17
        x &+= 1
    }
    return x
}

func runExperiment(concurrency: Int, totalTasks: Int, loops: Int, repeats: Int) {
    print("\n=== concurrency=\(concurrency), totalTasks=\(totalTasks), loops=\(loops) ===")

    var best: Double = .infinity
    var sink: UInt64 = 0

    for r in 1...repeats {
        let sem = DispatchSemaphore(value: concurrency)
        let group = DispatchGroup()
        let start = DispatchTime.now()

        print(">>> START run=\(r) concurrency=\(concurrency)")

        for i in 0..<totalTasks {
            sem.wait()
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                let v = heavyWork(i, loops: loops)
                // 최적화 방지용 집계
                _ = v
                sem.signal()
                group.leave()
            }
        }

        group.wait()

        print("<<< END   run=\(r) concurrency=\(concurrency)")

        let end = DispatchTime.now()
        let elapsed = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000.0
        best = min(best, elapsed)
        sink &+= UInt64(r)
        print("run \(r): \(String(format: "%.3f", elapsed))s")
    }

    let throughput = Double(totalTasks) / best
    print("best: \(String(format: "%.3f", best))s | throughput: \(String(format: "%.1f", throughput)) tasks/s | sink: \(sink)")
}

let cpuCount = ProcessInfo.processInfo.activeProcessorCount
print("Active CPU cores: \(cpuCount)")

let totalTasks = 80        // 8 * cpuCount (cpuCount=10)
let loops = 1_000_000
let repeats = 3

let sweep = [1, 2, 4, 5, 10, 20, 40]
for c in sweep {
    runExperiment(concurrency: c, totalTasks: totalTasks, loops: loops, repeats: repeats)
}
