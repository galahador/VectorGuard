//
//  SensorReading.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 13/05/2026.
//

import Foundation

public struct SensorReading: Sendable {

    public let acceleration: SensorVector
    public let gyroscope: SensorVector
    public let attitude: DeviceAttitude
    public let heading: Double?
    public let trueHeading: Double?
    public let headingAccuracy: Double?
    public let timestamp: TimeInterval
    public let state: MotionState
    public let motionConfidence: Double
    public let pressure: Double?
    public let relativeAltitude: Double?
}
