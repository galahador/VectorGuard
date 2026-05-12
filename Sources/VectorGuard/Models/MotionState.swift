//
//  MotionState.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation

/// The current motion state inferred from sensor data.
public enum MotionState: Equatable, Sendable, CustomStringConvertible {
    
    /// Device is at rest no significant acceleration detected.
    case idle
    
    /// Sustained movement detected above the movement threshold.
    ///
    /// - Parameter intensity: Average user acceleration magnitude during this period.
    case moving(intensity: Double)
    
    /// A short, sharp acceleration spike the device was grabbed, dropped, or thrown.
    ///
    /// - Parameter vector: The raw user acceleration vector at the moment of the spike.
    case rapidMovement(vector: SensorVector)
    
    /// Repeated direction reversals within a short window someone shaking the device.
    case jiggling
    
    // MARK: - Equatable (coarse: only compares the case, not associated values)
    
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
