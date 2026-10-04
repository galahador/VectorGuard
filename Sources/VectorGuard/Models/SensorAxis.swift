//
//  SensorAxis.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 04/10/2026.
//

import Foundation

public enum SensorAxis: Equatable, Hashable, Sendable, CustomStringConvertible {
    case x
    case y
    case z

    public var description: String {
        switch self {
        case .x: return "x"
        case .y: return "y"
        case .z: return "z"
        }
    }
}
