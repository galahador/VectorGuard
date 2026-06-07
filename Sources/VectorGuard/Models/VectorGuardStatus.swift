//
//  VectorGuardStatus.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 13/05/2026.
//

import Foundation

/// A point-in-time snapshot of everything VectorGuard knows.
///
/// Obtain the current snapshot via ``VectorGuard/status``:
///
/// ```swift
/// let status = VectorGuard.shared.status
/// print(status.currentState)      // e.g. moving(intensity: 0.42 g)
/// print(status.lastHeading)       // e.g. Optional(273.5)
/// print(status.isMonitoring)      // true / false
/// ```
///
/// Because `VectorGuardStatus` is a value type, every call to `.status` captures
/// an independent, immutable snapshot — safe to pass between threads.
public struct VectorGuardStatus: Sendable {

    // MARK: - Lifecycle

    /// Whether VectorGuard is actively collecting sensor data.
    public let isMonitoring: Bool

    // MARK: - Motion State

    /// The most recently inferred motion state.
    public let currentState: MotionState

    /// `true` when the device is stationary.
    public var isIdle: Bool { currentState == .idle }

    /// `true` when the device is being carried or moved steadily.
    public var isMoving: Bool {
        if case .moving = currentState { return true }
        return false
    }

    /// `true` when a sudden grab, drop, or throw was just detected.
    public var isRapidMovement: Bool {
        if case .rapidMovement = currentState { return true }
        return false
    }

    /// `true` when repeated shaking is detected.
    public var isJiggling: Bool { currentState == .jiggling }

    // MARK: - Raw Sensor Readings

    /// The most recent user-acceleration vector from the motion sensor (g).
    ///
    /// `nil` until the first sensor frame arrives after ``VectorGuard/startMonitoring()``.
    public let lastAcceleration: SensorVector?

    /// The most recent rotation-rate vector from the gyroscope (rad/s).
    ///
    /// `nil` until the first sensor frame arrives after ``VectorGuard/startMonitoring()``.
    public let lastGyroscope: SensorVector?

    /// The most recent device orientation (pitch/roll/yaw, in degrees).
    ///
    /// `nil` until the first sensor frame arrives after ``VectorGuard/startMonitoring()``.
    public let lastAttitude: DeviceAttitude?

    /// The most recent compass heading in degrees (0–360, magnetic north).
    ///
    /// `nil` on devices without a compass, or before the first heading update.
    public let lastHeading: Double?

    public let lastTrueHeading: Double?

    public let lastHeadingAccuracy: Double?

    /// The most recent barometric pressure in kilopascals.
    ///
    /// `nil` on devices without a barometer or before the first barometer update.
    public let lastPressure: Double?

    /// Relative altitude in metres since monitoring started.
    ///
    /// `nil` on devices without a barometer or before the first barometer update.
    public let lastRelativeAltitude: Double?

    // MARK: - Event History

    /// The most recently emitted ``VectorGuardEvent``.
    ///
    /// `nil` if no event has been emitted since monitoring started.
    public let lastEvent: VectorGuardEvent?

    /// Wall-clock time at which ``lastEvent`` was emitted.
    ///
    /// `nil` if no event has been emitted since monitoring started.
    public let lastEventDate: Date?

    // MARK: - Init (internal — created by VectorGuard.status)

    init(
        isMonitoring: Bool,
        currentState: MotionState,
        lastAcceleration: SensorVector?,
        lastGyroscope: SensorVector?,
        lastAttitude: DeviceAttitude?,
        lastHeading: Double?,
        lastTrueHeading: Double?,
        lastHeadingAccuracy: Double?,
        lastPressure: Double?,
        lastRelativeAltitude: Double?,
        lastEvent: VectorGuardEvent?,
        lastEventDate: Date?
    ) {
        self.isMonitoring        = isMonitoring
        self.currentState        = currentState
        self.lastAcceleration    = lastAcceleration
        self.lastGyroscope       = lastGyroscope
        self.lastAttitude        = lastAttitude
        self.lastHeading         = lastHeading
        self.lastTrueHeading     = lastTrueHeading
        self.lastHeadingAccuracy = lastHeadingAccuracy
        self.lastPressure        = lastPressure
        self.lastRelativeAltitude = lastRelativeAltitude
        self.lastEvent           = lastEvent
        self.lastEventDate       = lastEventDate
    }
}
