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
    
    private var lastHeading: Double?
    
    // MARK: - Init
    init(configuration: VectorGuardConfiguration) {
        self.configuration = configuration
        let cap = Self.bufferCapacity(for: configuration)
        self.accelBuffer    = SignalBuffer(capacity: cap)
        self.idleSampleTarget = Self.idleSampleTarget(for: configuration)
    }
    
    // MARK: - Processing
    
    func process(accelerometer: AccelerometerSample, gyroscope: GyroscopeSample) {
        processAccelerometer(accelerometer)
        processGyroscope(gyroscope)
    }
    
    func process(heading: Double) {
        guard let last = lastHeading else { lastHeading = heading; return }
        var delta = heading - last
        if delta >  180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        if abs(delta) >= configuration.headingChangedThreshold {
            emit(.headingChanged(current: heading, delta: delta))
            lastHeading = heading
        }
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
