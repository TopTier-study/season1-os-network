//
//  stringExtension.swift
//  semaphore
//
//  Created by 이상유 on 2026-03-12.
//

// String 반복 연산자
extension String {
    static func * (lhs: String, rhs: Int) -> String {
        String(repeating: lhs, count: rhs)
    }
}
