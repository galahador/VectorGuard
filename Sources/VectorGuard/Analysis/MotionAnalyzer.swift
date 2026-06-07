//
//  MotionAnalyzer.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation

/// Stateful detection engine that classifies raw sensor samples into motion states and events.
///
/// All methods must be called on the **main actor**.
@MainActor
final class MotionAnalyzer {
    
    // MARK: - Configuration
    var configuration: VectorGuardConfiguration {
        didSet { reconfigureBuffers() }
    }
    
    // MARK: - Output
    var onEvent: ((VectorGuardEvent) -> Void)?
    
    // MARK: - State
    private(set) var currentState: MotionState = .idle
    
    // MARK: - Accelerometer / movement tracking
    private var accelBuffer: SignalBuffer
    private var movingCount  = 0
    private var idleCount    = 0
    private var idleSampleTarget: Int
    
    // MARK: - Internal: Rapid movement debounce
    
    private var lastRapidMovementTime: TimeInterval = -.infinity
    private var rapidMovementEnteredAt: TimeInterval = -.infinity
    
    // MARK: - Internal: Jiggling detection
    
    /// Timestamps of axis-direction reversals inside the jiggling window.
    private var reversalTimestamps: [TimeInterval] = []
    /// Sign of the previous significant gyroscope reading per axis: -1, 0, or +1.
    private var prevGyroSign = (x: 0, y: 0, z: 0)
    
    // MARK: - Internal: Compass

    private var smoothedHeadingVector: (cos: Double, sin: Double)?
    
    private var lastEmittedHeading: Double?

    // MARK: - Internal: Attitude

    private var lastAttitude: DeviceAttitude?

    // MARK: - Init
    init(configuration: VectorGuardConfiguration) {
        self.configuration = configuration
        let cap = Self.bufferCapacity(for: configuration)
        self.accelBuffer    = SignalBuffer(capacity: cap)
        self.idleSampleTarget = Self.idleSampleTarget(for: configuration)
    }
    
    // MARK: - Processing
    
    func process(accelerometer: AccelerometerSample, gyroscope: GyroscopeSample, attitude: DeviceAttitude) {
        processAccelerometer(accelerometer)
        processGyroscope(gyroscope)
        processAttitude(attitude)
    }

    func process(heading rawHeading: Double) {
        let heading = smoothed(heading: rawHeading)
        guard let last = lastEmittedHeading else { lastEmittedHeading = heading; return }
        let delta = Self.angularDelta(from: last, to: heading)
        let thresholds = configuration.headingChangeThresholds
        if let crossed = thresholds.filter({ abs(delta) >= $0 }).max() {
            emit(.headingChanged(current: heading, delta: delta, threshold: crossed))
            lastEmittedHeading = heading
        }
    }

    // MARK: - Private: Attitude

    private func processAttitude(_ attitude: DeviceAttitude) {
        guard let last = lastAttitude else { lastAttitude = attitude; return }
        let deltaPitch = attitude.pitch - last.pitch
        let deltaRoll  = Self.angularDelta(from: last.roll, to: attitude.roll)
        let deltaYaw   = Self.angularDelta(from: last.yaw, to: attitude.yaw)
        let magnitude  = (deltaPitch * deltaPitch + deltaRoll * deltaRoll + deltaYaw * deltaYaw).squareRoot()
        if magnitude >= configuration.attitudeChangeThreshold {
            emit(.attitudeChanged(
                current: attitude,
                delta: DeviceAttitude(pitch: deltaPitch, roll: deltaRoll, yaw: deltaYaw)
            ))
            lastAttitude = attitude
        }
    }

    private func smoothed(heading rawHeading: Double) -> Double {
        let radians = rawHeading * .pi / 180
        let sample  = (cos: cos(radians), sin: sin(radians))
        let factor  = configuration.headingSmoothingFactor
        let blended: (cos: Double, sin: Double)
        if let prev = smoothedHeadingVector {
            blended = (
                cos: factor * sample.cos + (1 - factor) * prev.cos,
                sin: factor * sample.sin + (1 - factor) * prev.sin
            )
        } else {
            blended = sample
        }
        smoothedHeadingVector = blended
        var degrees = atan2(blended.sin, blended.cos) * 180 / .pi
        if degrees < 0 { degrees += 360 }
        return degrees
    }

    /// Shortest signed angular distance from `a` to `b`, in degrees, wrapped to `-180...180`.
    private static func angularDelta(from a: Double, to b: Double) -> Double {
        var delta = b - a
        if delta >  180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        return delta
    }
    
    // MARK: - Private: Accelerometer
    
    private func processAccelerometer(_ sample: AccelerometerSample) {
        let mag = sample.userAcceleration.magnitude
        accelBuffer.push(mag)
        
        // Rapid movement — immediate, high-priority classification
        let now = sample.timestamp
        if mag >= configuration.rapidMovementThreshold,
           now - lastRapidMovementTime > configuration.rapidMovementDebounce {
            let wasIdle = currentState == .idle
            lastRapidMovementTime = now
            rapidMovementEnteredAt = now
            emit(.accelerationSpike(magnitude: mag, vector: sample.userAcceleration))
            transition(to: .rapidMovement(vector: sample.userAcceleration))
            if wasIdle { emit(.devicePickedUp) }
            movingCount = 0
            idleCount   = 0
            return
        }
        
        // Hysteresis counters
        if mag >= configuration.movementThreshold {
            movingCount += 1
            idleCount    = 0
        } else {
            idleCount   += 1
            movingCount  = 0
        }
        
        updateMovingOrIdle(magnitude: mag, timestamp: now)
    }
    
    private func updateMovingOrIdle(magnitude: Double, timestamp: TimeInterval) {
        switch currentState {
            
        case .idle:
            if movingCount >= configuration.movementConfirmationSamples {
                transition(to: .moving(intensity: magnitude))
                emit(.devicePickedUp)
            }
            
        case .moving:
            if idleCount >= idleSampleTarget {
                transition(to: .idle)
                emit(.devicePutDown)
            } else {
                // Update intensity in-place (no state-change event)
                currentState = .moving(intensity: accelBuffer.average)
            }
            
        case .jiggling:
            if idleCount >= idleSampleTarget {
                transition(to: .idle)
                emit(.devicePutDown)
            }
            
        case .rapidMovement:
            let elapsed     = timestamp - rapidMovementEnteredAt
            let quickSettle = max(3, idleSampleTarget / 3)
            if elapsed >= configuration.idleTimeout || idleCount >= quickSettle {
                transition(to: .idle)
                emit(.devicePutDown)
            } else if movingCount >= configuration.movementConfirmationSamples {
                transition(to: .moving(intensity: magnitude))
            }
        }
    }
    
    // MARK: - Private: Gyroscope
    
    private func processGyroscope(_ sample: GyroscopeSample) {
        let rv  = sample.rotationRate
        let mag = rv.magnitude
        
        // Rotation spike
        if mag >= configuration.rapidMovementThreshold * 1.5 {
            emit(.rotationSpike(magnitude: mag, vector: rv))
        }
        
        // Jiggling: count axis-direction reversals
        let threshold = configuration.jigglingGyroThreshold
        guard mag >= threshold else { return }
        
        let sx = axisSign(rv.x)
        let sy = axisSign(rv.y)
        let sz = axisSign(rv.z)
        
        let reversed = (prevGyroSign.x != 0 && sx != 0 && sx != prevGyroSign.x)
        || (prevGyroSign.y != 0 && sy != 0 && sy != prevGyroSign.y)
        || (prevGyroSign.z != 0 && sz != 0 && sz != prevGyroSign.z)
        
        if reversed { reversalTimestamps.append(sample.timestamp) }
        prevGyroSign = (sx, sy, sz)
        
        // Prune reversals that have fallen outside the window
        let windowStart = sample.timestamp - configuration.jigglingWindow
        reversalTimestamps.removeAll { $0 < windowStart }
        
        if reversalTimestamps.count >= configuration.jigglingReversalCount,
           currentState != .jiggling {
            transition(to: .jiggling)
            emit(.jigglingDetected)
            reversalTimestamps.removeAll()   // reset after triggering
        }
    }
    
    // MARK: - Private
    
    private func transition(to newState: MotionState) {
        guard currentState != newState else { return }
        let old = currentState
        currentState = newState
        emit(.stateChanged(from: old, to: newState))
    }
    
    private func emit(_ event: VectorGuardEvent) {
        onEvent?(event)
    }
    
    private func reconfigureBuffers() {
        let newCap = Self.bufferCapacity(for: configuration)
        idleSampleTarget = Self.idleSampleTarget(for: configuration)
        guard newCap != accelBuffer.capacity else { return }
        accelBuffer = SignalBuffer(capacity: newCap)
    }
    
    private func axisSign(_ value: Double) -> Int {
        if value >  0.01 { return  1 }
        if value < -0.01 { return -1 }
        return 0
    }
    
    private static func bufferCapacity(for cfg: VectorGuardConfiguration) -> Int {
        max(10, Int((cfg.idleTimeout / cfg.sensorUpdateInterval).rounded(.up)))
    }
    
    private static func idleSampleTarget(for cfg: VectorGuardConfiguration) -> Int {
        max(1, Int((cfg.idleTimeout / cfg.sensorUpdateInterval).rounded(.up)))
    }
}
