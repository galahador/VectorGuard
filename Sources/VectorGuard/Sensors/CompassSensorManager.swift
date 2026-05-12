//
//  CompassSensorManager.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation

#if os(iOS)

import CoreLocation

/// Internal wrapper around `CLLocationManager` for compass / magnetic-heading data.
///
/// All callbacks are dispatched to the **main actor**.
final class CompassSensorManager: NSObject, @unchecked Sendable {

    private let locationManager = CLLocationManager()
    private var headingHandler: (@MainActor (Double) -> Void)?

    var isAvailable: Bool { CLLocationManager.headingAvailable() }

    func startUpdates(handler: @escaping @MainActor (Double) -> Void) {
        guard isAvailable else { return }
        headingHandler = handler
        locationManager.delegate = self
        locationManager.headingFilter = 1.0
        locationManager.startUpdatingHeading()
    }

    func stopUpdates() {
        locationManager.stopUpdatingHeading()
        locationManager.delegate = nil
        headingHandler = nil
    }
}

// MARK: - CLLocationManagerDelegate

extension CompassSensorManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        let degrees = newHeading.magneticHeading
        let handler = headingHandler
        Task { @MainActor in handler?(degrees) }
    }
}

#else

/// Stub for non-iOS platforms. Compass is unavailable. :/
final class CompassSensorManager: @unchecked Sendable {
    var isAvailable: Bool { false }
    func startUpdates(handler: @escaping @MainActor (Double) -> Void) {}
    func stopUpdates() {}
}

#endif
