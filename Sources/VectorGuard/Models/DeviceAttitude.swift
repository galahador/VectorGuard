//
//  DeviceAttitude.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 07/06/2026.
//

import Foundation

/// The device's spatial orientation, expressed as pitch / roll / yaw in degrees.
///
/// Derived from `CMDeviceMotion.attitude`. Useful for detecting orientation changes that
/// acceleration and compass heading alone can't describe — e.g. a phone being flipped face
/// down, tipped out of a pocket, or rotated flat on a table.
///
/// ```swift
/// let attitude = VectorGuard.shared.status.lastAttitude
/// print(attitude?.pitch, attitude?.roll, attitude?.yaw)
/// ```
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
