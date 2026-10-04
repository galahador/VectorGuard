//
//  DeviceAttitude.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 07/06/2026.
//

import Foundation

public struct DeviceAttitude: Equatable, Hashable, Sendable {

    public let pitch: Double

    public let roll: Double
    
    public let yaw: Double

    public init(pitch: Double, roll: Double, yaw: Double) {
        self.pitch = pitch
        self.roll  = roll
        self.yaw   = yaw
    }

    public static let zero = DeviceAttitude(pitch: 0, roll: 0, yaw: 0)
}
