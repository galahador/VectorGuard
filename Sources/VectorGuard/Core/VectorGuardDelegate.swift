//
//  VectorGuardDelegate.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation

/// Implement this protocol to receive motion events from VectorGuard.
///
/// All delegate calls are delivered on the **main thread**.
///
/// ## Example
/// ```swift
/// extension MyViewController: VectorGuardDelegate {
///     func vectorGuard(_ guard: VectorGuard, didDetect event: VectorGuardEvent) {
///         switch event {
///         case .devicePickedUp:
///             triggerAlarm()
///         case .stateChanged(_, let new):
///             print("New state:", new)
///         default:
///             break
///         }
///     }
/// }
/// ```
public protocol VectorGuardDelegate: AnyObject {

    /// Called whenever VectorGuard detects a new motion event.
    ///
    /// - Parameters:
    ///   - guard: The shared VectorGuard instance.
    ///   - event: The detected event.
    func vectorGuard(_ guard: VectorGuard, didDetect event: VectorGuardEvent)
}
