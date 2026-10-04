//
//  IdleSurfaceState.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 04/10/2026.
//

import Foundation

public enum IdleSurfaceState: Equatable, Sendable, CustomStringConvertible {
    case unknown
    case restingOnSurface
    case heldStill

    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .restingOnSurface: return "restingOnSurface"
        case .heldStill: return "heldStill"
        }
    }
}
