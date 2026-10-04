//
//  MotionSensorManager.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation

// MARK: - Sample Types (shared across all platforms)

struct AccelerometerSample: Sendable {
    let userAcceleration: SensorVector
    let gravity: SensorVector
    let timestamp: TimeInterval
}

struct GyroscopeSample: Sendable {
    let rotationRate: SensorVector
    let timestamp: TimeInterval
}

private let radiansToDegrees = 180.0 / Double.pi
func makeDeviceAttitude(pitch: Double, roll: Double, yaw: Double) -> DeviceAttitude {
    DeviceAttitude(
        pitch: pitch * radiansToDegrees,
        roll:  roll  * radiansToDegrees,
        yaw:   yaw   * radiansToDegrees
    )
}

// MARK: - Manager
#if os(iOS)

import CoreMotion

final class MotionSensorManager: @unchecked Sendable {

    private let motionManager = CMMotionManager()

    var isAvailable: Bool { motionManager.isDeviceMotionAvailable }

    func startUpdates(
        interval: TimeInterval,
        handler: @escaping @MainActor (AccelerometerSample, GyroscopeSample, DeviceAttitude) -> Void
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
            let attitude = makeDeviceAttitude(
                pitch: motion.attitude.pitch,
                roll:  motion.attitude.roll,
                yaw:   motion.attitude.yaw
            )
            MainActor.assumeIsolated { handler(accel, gyro, attitude) }
        }
    }

    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}

#else
final class MotionSensorManager: @unchecked Sendable {
    var isAvailable: Bool { false }
    func startUpdates(
        interval: TimeInterval,
        handler: @escaping @MainActor (AccelerometerSample, GyroscopeSample, DeviceAttitude) -> Void
    ) {}
    func stopUpdates() {}
}

#endif
