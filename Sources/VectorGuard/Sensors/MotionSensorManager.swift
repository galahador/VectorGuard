//
//  MotionSensorManager.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation

// MARK: - Sample Types (shared across all platforms)

/// A single device-motion frame containing gravity acceleration.
struct AccelerometerSample: Sendable {
    /// Acceleration excluding gravity g
    let userAcceleration: SensorVector
    /// Gravity vector g
    let gravity: SensorVector
    /// CoreMotion timestamp (seconds since device boot).
    let timestamp: TimeInterval
}

/// A single gyroscope frame.
struct GyroscopeSample: Sendable {
    /// Angular velocity rad/s
    let rotationRate: SensorVector
    /// CoreMotion timestamp (seconds since device boot).
    let timestamp: TimeInterval
}

// MARK: - Manager

#if os(iOS)

import CoreMotion
/// - All callbacks are dispatched back to the **main actor**.
/// - Uses `CMDeviceMotion` fusion which provides both gravity-subtracted user
///   acceleration and gyroscope rotation rate in a single subscription,
///   reducing battery impact vs. two separate subscriptions.
final class MotionSensorManager: @unchecked Sendable {

    private let motionManager = CMMotionManager()

    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.name = "com.vectorguard.motion"
        q.qualityOfService = .userInteractive
        q.maxConcurrentOperationCount = 1
        return q
    }()

    var isAvailable: Bool { motionManager.isDeviceMotionAvailable }

    func startUpdates(
        interval: TimeInterval,
        handler: @escaping @MainActor (AccelerometerSample, GyroscopeSample) -> Void
    ) {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = interval
        motionManager.startDeviceMotionUpdates(to: queue) { motion, error in
            guard let motion, error == nil else { return }
            let accel = AccelerometerSample(
                userAcceleration: SensorVector(
                    x: motion.userAcceleration.x,
                    y: motion.userAcceleration.y,
                    z: motion.userAcceleration.z
                ),
                gravity: SensorVector(
                    x: motion.gravity.x,
                    y: motion.gravity.y,
                    z: motion.gravity.z
                ),
                timestamp: motion.timestamp
            )
            let gyro = GyroscopeSample(
                rotationRate: SensorVector(
                    x: motion.rotationRate.x,
                    y: motion.rotationRate.y,
                    z: motion.rotationRate.z
                ),
                timestamp: motion.timestamp
            )
            Task { @MainActor in handler(accel, gyro) }
        }
    }

    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}

#else

/// Stub for non-iOS platforms. Sensors are unavailable.
final class MotionSensorManager: @unchecked Sendable {
    var isAvailable: Bool { false }
    func startUpdates(
        interval: TimeInterval,
        handler: @escaping @MainActor (AccelerometerSample, GyroscopeSample) -> Void
    ) {}
    func stopUpdates() {}
}

#endif
