//
//  SensorReading.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 13/05/2026.
//

import Foundation

/// A single sensor frame delivered on every motion update (~20 Hz by default).
///
/// Obtain a live stream of readings via ``VectorGuard/monitorSensors()``:
///
/// ```swift
/// Task {
///     for await reading in VectorGuard.shared.monitorSensors() {
///         print(reading.acceleration.magnitude, "g")
///         print(reading.gyroscope.magnitude, "rad/s")
///         print(reading.heading ?? "-", "°")
///         print(reading.state)
///     }
/// }
/// ```
public struct SensorReading: Sendable {

    /// User-acceleration vector with gravity removed g
    public let acceleration: SensorVector

    /// Angular velocity vector from the gyroscope rad/s
    public let gyroscope: SensorVector

    /// Most recent compass heading in degrees 0–360, magnetic north
    ///
    /// `nil` on devices without a compass or before the first heading update.
    public let heading: Double?

    /// CoreMotion timestamp of this frame (seconds since device boot).
    public let timestamp: TimeInterval

    /// Motion state inferred by VectorGuard at the time this frame was processed.
    public let state: MotionState

    /// Most recent barometric pressure in kilopascals.
    ///
    /// `nil` on devices without a barometer or before the first barometer update.
    public let pressure: Double?

    /// Relative altitude in metres since monitoring started.
    ///
    /// `nil` on devices without a barometer or before the first barometer update.
    public let relativeAltitude: Double?
}
