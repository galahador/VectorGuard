//
//  VectorGuardConfiguration.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation

/// Thresholds and timing parameters that control VectorGuard's detection sensitivity.
///
/// All properties have sensible defaults. Adjust them to match case
/// (e.g. raise thresholds on a device mounted to a vehicle vs. carried in a pocket).
public struct VectorGuardConfiguration: Sendable {
    
    // MARK: - Sampling Rate
    
    /// How often the motion manager delivers new samples (seconds).
    ///
    /// Default: `0.05` s → 20 Hz. Lower values increase sensitivity and CPU usage.
    public var sensorUpdateInterval: TimeInterval = 0.05
    
    // MARK: - Movement Detection
    
    /// User-acceleration magnitude (g) above which the device is considered moving.
    ///
    /// Default: `0.08` g (filters out minor hand tremor).
    public var movementThreshold: Double = 0.08
    
    /// Consecutive samples above ``movementThreshold`` required before entering `.moving`.
    ///
    /// Default: `3`. Acts as a debounce to reject single-sample spikes.
    public var movementConfirmationSamples: Int = 3
    
    /// Seconds of low-acceleration data required before the device is declared `.idle` again.
    ///
    /// Default: `1.0` s.
    public var idleTimeout: TimeInterval = 1.0
    
    // MARK: - Rapid Movement
    
    /// User-acceleration magnitude (g) above which a ``VectorGuardEvent/accelerationSpike(magnitude:vector:)``
    /// is emitted and the state becomes `.rapidMovement`.
    ///
    /// Default: `1.5` g.
    public var rapidMovementThreshold: Double = 1.5
    
    /// Minimum time (seconds) between successive rapid-movement events (debounce).
    ///
    /// Default: `0.3` s.
    public var rapidMovementDebounce: TimeInterval = 0.3
    
    // MARK: - Jiggling Detection
    
    /// Angular-velocity magnitude (rad/s) above which a gyroscope sample is considered
    /// significant for jiggling analysis.
    ///
    /// Default: `1.2` rad/s.
    public var jigglingGyroThreshold: Double = 1.2
    
    /// Number of angular direction reversals within ``jigglingWindow`` that triggers `.jiggling`.
    ///
    /// Default: `4`.
    public var jigglingReversalCount: Int = 4
    
    /// Rolling time window (seconds) in which reversals are counted.
    ///
    /// Default: `0.8` s.
    public var jigglingWindow: TimeInterval = 0.8
    
    // MARK: - Compass
    
    /// Heading change (degrees) above which a ``VectorGuardEvent/headingChanged(current:delta:)``
    /// event is emitted.
    ///
    /// Default: `15°`.
    public var headingChangedThreshold: Double = 15.0
    
    // MARK: - Init
    
    public init() {}
}
