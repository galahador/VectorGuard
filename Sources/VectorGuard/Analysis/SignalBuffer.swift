//
//  SignalBuffer.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation

/// A fixed-capacity ring buffer that retains the N most recent scalar readings.

struct SignalBuffer {
    
    private var storage: [Double]
    private var head: Int = 0
    
    private(set) var count: Int = 0
    let capacity: Int
    
    init(capacity: Int) {
        precondition(capacity > 0, "SignalBuffer capacity must be positive")
        self.capacity = capacity
        self.storage = Array(repeating: 0, count: capacity)
    }
    
    // MARK: - Write
    
    mutating func push(_ value: Double) {
        storage[head] = value
        head = (head + 1) % capacity
        if count < capacity { count += 1 }
    }
    
    // MARK: - Read
    
    /// Values ordered from oldest to newest.
    var values: [Double] {
        guard count == capacity else { return Array(storage.prefix(count)) }
        return Array(storage[head...]) + Array(storage[..<head])
    }
    
    var average: Double {
        guard count > 0 else { return 0 }
        return values.reduce(0, +) / Double(count)
    }
    
    var isFull: Bool { count == capacity }
    
    var isEmpty: Bool { count == 0 }
}
