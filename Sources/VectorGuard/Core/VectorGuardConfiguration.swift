//
//  VectorGuardConfiguration.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation

public struct VectorGuardConfiguration: Sendable {
    
    // MARK: - Sampling Rate
    public var sensorUpdateInterval: TimeInterval = 0.05
    
    // MARK: - Movement Detection
    public var movementThreshold: Double = 0.08
    public var movementConfirmationSamples: Int = 3
    public var idleTimeout: TimeInterval = 1.0
    public var rapidMovementThreshold: Double = 1.5
    public var rapidMovementDebounce: TimeInterval = 0.3
    public var jigglingGyroThreshold: Double = 1.2
    public var jigglingReversalCount: Int = 4
    public var jigglingWindow: TimeInterval = 0.8
    public var accelSmoothingFactor: Double = 0.3
    public var headingSmoothingFactor: Double = 0.25
    public var headingChangeThresholds: [Double] = [15.0, 45.0, 120.0]
    public var attitudeChangeThreshold: Double = 20.0
    public var altitudeChangeThreshold: Double = 1.0

    // MARK: - Init
    public init() {}

    // MARK: - Presets
    public static var sensitive: VectorGuardConfiguration {
        var c = VectorGuardConfiguration()
        c.movementThreshold            = 0.04
        c.movementConfirmationSamples  = 2
        c.rapidMovementThreshold       = 1.0
        c.jigglingGyroThreshold        = 0.8
        c.jigglingReversalCount        = 3
        c.accelSmoothingFactor         = 0.45
        c.headingSmoothingFactor       = 0.4
        c.headingChangeThresholds      = [8.0, 30.0, 90.0]
        c.attitudeChangeThreshold      = 12.0
        return c
    }
    
    public static var balanced: VectorGuardConfiguration {
        VectorGuardConfiguration()
    }

    public static var relaxed: VectorGuardConfiguration {
        var c = VectorGuardConfiguration()
        c.movementThreshold            = 0.15
        c.movementConfirmationSamples  = 5
        c.rapidMovementThreshold       = 2.5
        c.jigglingGyroThreshold        = 2.0
        c.jigglingReversalCount        = 6
        c.accelSmoothingFactor         = 0.2
        c.headingSmoothingFactor       = 0.15
        c.headingChangeThresholds      = [30.0, 75.0, 150.0]
        c.attitudeChangeThreshold      = 35.0
        return c
    }
}
