//
//  VectorGuardEvent.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation

public enum VectorGuardEvent: Sendable, Equatable {

    case stateChanged(from: MotionState, to: MotionState)
    case accelerationSpike(magnitude: Double, vector: SensorVector)
    case rotationSpike(magnitude: Double, vector: SensorVector)
    case headingChanged(current: Double, delta: Double, threshold: Double)
    case attitudeChanged(current: DeviceAttitude, delta: DeviceAttitude)
    case devicePickedUp
    case devicePutDown
    case jigglingDetected(intensity: Double, frequency: Double, dominantAxis: SensorAxis)
    case altitudeChanged(delta: Double, pressure: Double)
}
