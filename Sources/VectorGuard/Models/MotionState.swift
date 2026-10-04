//
//  MotionState.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation

public enum MotionState: Equatable, Sendable, CustomStringConvertible {
    case idle
    case moving(intensity: Double)
    case rapidMovement(vector: SensorVector)
    case jiggling
    
    // MARK: - Equatable
    public static func == (lhs: MotionState, rhs: MotionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):                         return true
        case (.moving, .moving):                     return true
        case (.rapidMovement, .rapidMovement):       return true
        case (.jiggling, .jiggling):                 return true
        default:                                     return false
        }
    }
    
    // MARK: - CustomStringConvertible
    public var description: String {
        switch self {
        case .idle:
            return "idle"
        case .moving(let intensity):
            return String(format: "moving(intensity: %.2f g)", intensity)
        case .rapidMovement(let v):
            return String(format: "rapidMovement(magnitude: %.2f g)", v.magnitude)
        case .jiggling:
            return "jiggling"
        }
    }
}
