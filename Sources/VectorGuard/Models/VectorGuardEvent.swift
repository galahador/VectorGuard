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
public enum VectorGuardEvent: Sendable {

    /// The inferred motion state changed.
    case stateChanged(from: MotionState, to: MotionState)

    /// A sharp linear-acceleration spike was detected (device grabbed or dropped).
    case accelerationSpike(magnitude: Double, vector: SensorVector)

    /// A sharp angular-velocity spike was detected (rapid twist or flip).
    case rotationSpike(magnitude: Double, vector: SensorVector)

    /// Compass heading changed by more than ``VectorGuardConfiguration/headingChangedThreshold``.
    case headingChanged(current: Double, delta: Double)

    /// Device transitioned from idle to moving (pick-up event.)
    case devicePickedUp

    /// Device transitioned from moving to idle (put-down event.)
    case devicePutDown

    /// Relative altitude changed by more than ``VectorGuardConfiguration/altitudeChangeThreshold``.
    ///
    /// - Parameters:
    ///   - delta: Change in metres since the last emitted altitude event (positive = up, negative = down).
    ///   - pressure: Current barometric pressure in kilopascals.
    case altitudeChanged(delta: Double, pressure: Double)
}
