//
//  VectorGuardStatus.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 13/05/2026.
//

import Foundation

public struct VectorGuardStatus: Sendable {

    // MARK: - Lifecycle
    public let isMonitoring: Bool

    // MARK: - Motion State
    public let currentState: MotionState
    public var isIdle: Bool { currentState == .idle }
    
    public var isMoving: Bool {
        if case .moving = currentState { return true }
        return false
    }
    
    public var isRapidMovement: Bool {
        if case .rapidMovement = currentState { return true }
        return false
    }

    public var isJiggling: Bool {
        if case .jiggling = currentState { return true }
        return false
    }

    public let motionConfidence: Double
    public let orientation: DeviceOrientation
    public let idleSurfaceState: IdleSurfaceState

    // MARK: - Raw Sensor Readings
    public let lastAcceleration: SensorVector?
    public let lastGyroscope: SensorVector?
    public let lastAttitude: DeviceAttitude?
    public let lastHeading: Double?
    public let lastTrueHeading: Double?
    public let lastHeadingAccuracy: Double?
    public let lastPressure: Double?
    public let lastRelativeAltitude: Double?

    // MARK: - Event History
    public let lastEvent: VectorGuardEvent?
    public let lastEventDate: Date?

    // MARK: - Init
    init(
        isMonitoring: Bool,
        currentState: MotionState,
        motionConfidence: Double,
        orientation: DeviceOrientation,
        idleSurfaceState: IdleSurfaceState,
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
        self.motionConfidence    = motionConfidence
        self.orientation         = orientation
        self.idleSurfaceState    = idleSurfaceState
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
