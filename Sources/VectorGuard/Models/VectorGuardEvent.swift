//
//  VectorGuardEvent.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation

/// A discrete event emitted by VectorGuard.
///
/// All events are delivered on the **main thread** via ``VectorGuardDelegate``.
public enum VectorGuardEvent: Sendable, Equatable {

    /// The inferred motion state changed.
    case stateChanged(from: MotionState, to: MotionState)

    /// A sharp linear-acceleration spike was detected (device grabbed or dropped).
    case accelerationSpike(magnitude: Double, vector: SensorVector)

    /// A sharp angular-velocity spike was detected (rapid twist or flip).
    case rotationSpike(magnitude: Double, vector: SensorVector)

    /// Cumulative compass-heading rotation (since the last emitted heading event) crossed one
    case headingChanged(current: Double, delta: Double, threshold: Double)

    /// Device orientation (pitch/roll/yaw) changed by more than
    case attitudeChanged(current: DeviceAttitude, delta: DeviceAttitude)

    /// Device transitioned from idle to moving (pick-up event.)
    case devicePickedUp

    /// Device transitioned from moving to idle (put-down event.)
    case devicePutDown

    /// Repeated direction reversals were detected — someone is shaking or jiggling the device
    case jigglingDetected

    case altitudeChanged(delta: Double, pressure: Double)
}
