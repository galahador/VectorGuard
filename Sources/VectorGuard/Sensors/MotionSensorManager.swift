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
/// - Updates are delivered on `OperationQueue.main`, which guarantees both main-actor
///   isolation and **in-order delivery** — critical, since ``MotionAnalyzer`` relies on
///   monotonically increasing timestamps for debouncing and windowed detection. Routing
///   through a background queue and hopping back via unstructured `Task`s would not
///   preserve that ordering.
/// - Uses `CMDeviceMotion` fusion which provides both gravity-subtracted user
///   acceleration and gyroscope rotation rate in a single subscription,
///   reducing battery impact vs. two separate subscriptions.
final class MotionSensorManager: @unchecked Sendable {

    private let motionManager = CMMotionManager()

    var isAvailable: Bool { motionManager.isDeviceMotionAvailable }

    func startUpdates(
        interval: TimeInterval,
        handler: @escaping @MainActor (AccelerometerSample, GyroscopeSample) -> Void
    ) {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = interval
        motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
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
            // CMMotionManager guarantees callbacks on `.main` arrive on the main thread,
            // in order — safe to assert main-actor isolation and call synchronously rather
            // than hopping through an unstructured Task (which would not preserve order).
            MainActor.assumeIsolated { handler(accel, gyro) }
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
