//
//  VectorGuardDiagnostics.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 04/10/2026.
//

import Foundation

public struct VectorGuardDiagnostics: Sendable {

    public let timestamp: TimeInterval
    public let rawAccelMagnitude: Double
    public let smoothedAccelMagnitude: Double
    public let effectiveMovementThreshold: Double
    public let isCalibrating: Bool
    public let movingCount: Int
    public let idleCount: Int
    public let reversalCount: Int
    public let reversalFrequency: Double
    public let motionConfidence: Double
}
