//
//  DeviceOrientation.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 04/10/2026.
//

import Foundation

public enum DeviceOrientation: Equatable, Sendable, CustomStringConvertible {
    case faceUp
    case faceDown
    case portrait
    case portraitUpsideDown
    case landscapeLeft
    case landscapeRight
    case unknown

    public var description: String {
        switch self {
        case .faceUp: return "faceUp"
        case .faceDown: return "faceDown"
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portraitUpsideDown"
        case .landscapeLeft: return "landscapeLeft"
        case .landscapeRight: return "landscapeRight"
        case .unknown: return "unknown"
        }
    }

    static func classify(gravity: SensorVector, threshold: Double) -> DeviceOrientation {
        if gravity.z <= -threshold { return .faceUp }
        if gravity.z >=  threshold { return .faceDown }
        if gravity.y <= -threshold { return .portrait }
        if gravity.y >=  threshold { return .portraitUpsideDown }
        if gravity.x <= -threshold { return .landscapeLeft }
        if gravity.x >=  threshold { return .landscapeRight }
        return .unknown
    }
}
