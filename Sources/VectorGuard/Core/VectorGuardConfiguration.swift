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
    public var freeFallThreshold: Double = 0.25
    public var freeFallMinDuration: TimeInterval = 0.1
    public var orientationThreshold: Double = 0.75
    public var gravitySmoothingFactor: Double = 0.2
    public var restingSurfaceNoiseThreshold: Double = 0.01
    public var maxHeadingAccuracy: Double = 35.0

    // MARK: - Init
    public init() {}

    // MARK: - Presets
    public static var sensitive: VectorGuardConfiguration {
        var config = VectorGuardConfiguration()
        config.movementThreshold            = 0.04
        config.movementConfirmationSamples  = 2
        config.rapidMovementThreshold       = 1.0
        config.jigglingGyroThreshold        = 0.8
        config.jigglingReversalCount        = 3
        config.accelSmoothingFactor         = 0.45
        config.headingSmoothingFactor       = 0.41
        config.headingChangeThresholds      = [8.0, 30.0, 90.0]
        config.attitudeChangeThreshold      = 12.0
        config.freeFallThreshold            = 0.35
        config.restingSurfaceNoiseThreshold = 0.006
        config.maxHeadingAccuracy           = 50.0
        return config
    }
    
    public static var balanced: VectorGuardConfiguration {
        VectorGuardConfiguration()
    }

    public static var relaxed: VectorGuardConfiguration {
        var config = VectorGuardConfiguration()
        config.movementThreshold            = 0.15
        config.movementConfirmationSamples  = 5
        config.rapidMovementThreshold       = 2.5
        config.jigglingGyroThreshold        = 2.0
        config.jigglingReversalCount        = 6
        config.accelSmoothingFactor         = 0.2
        config.headingSmoothingFactor       = 0.15
        config.headingChangeThresholds      = [30.0, 75.0, 150.0]
        config.attitudeChangeThreshold      = 35.0
        config.freeFallThreshold            = 0.15
        config.restingSurfaceNoiseThreshold = 0.02
        config.maxHeadingAccuracy           = 20.0
        return config
    }
}
