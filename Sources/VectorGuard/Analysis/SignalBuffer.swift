//
//  SignalBuffer.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation

struct SignalBuffer {
    
    private var storage: [Double]
    private var head: Int = 0
    private var runningSum: Double = 0
    private var runningSumSq: Double = 0

    private(set) var count: Int = 0
    let capacity: Int

    init(capacity: Int) {
        precondition(capacity > 0, "SignalBuffer capacity must be positive")
        self.capacity = capacity
        self.storage = Array(repeating: 0, count: capacity)
    }

    // MARK: - Write

    mutating func push(_ value: Double) {
        if count == capacity {
            runningSum   -= storage[head]
            runningSumSq -= storage[head] * storage[head]
        }
        storage[head] = value
        runningSum   += value
        runningSumSq += value * value
        head = (head + 1) % capacity
        if count < capacity { count += 1 }
    }

    // MARK: - Read
    var values: [Double] {
        guard count == capacity else { return Array(storage.prefix(count)) }
        return Array(storage[head...]) + Array(storage[..<head])
    }

    var average: Double {
        guard count > 0 else { return 0 }
        return runningSum / Double(count)
    }

    var variance: Double {
        guard count > 0 else { return 0 }
        let mean = average
        return max(0, runningSumSq / Double(count) - mean * mean)
    }

    var standardDeviation: Double { variance.squareRoot() }

    var isFull: Bool { count == capacity }
    var isEmpty: Bool { count == 0 }
}
