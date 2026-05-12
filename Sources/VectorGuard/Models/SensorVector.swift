//
//  SensorVector.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation

/// A three dimensional sensor reading.
public struct SensorVector: Equatable, Hashable, Sendable {
    
    public let x: Double
    public let y: Double
    public let z: Double
    
    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    public var magnitude: Double {
        (x * x + y * y + z * z).squareRoot()
    }
    
    public static let zero = SensorVector(x: 0, y: 0, z: 0)
}
