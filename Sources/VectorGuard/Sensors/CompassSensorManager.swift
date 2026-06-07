//
//  CompassSensorManager.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation

// MARK: - Sample Type (shared across all platforms)

/// A single compass heading frame.
struct CompassSample: Sendable {
    
    let magneticHeading: Double
    
    let trueHeading: Double?

    let accuracy: Double
}

#if os(iOS)

import CoreLocation

/// Internal wrapper around `CLLocationManager` for compass / magnetic-heading data.
///
/// `startUpdates` is always invoked on the main actor (see ``VectorGuard``), so
/// `CLLocationManager` delivers its delegate callbacks on the main run loop, in order —
/// safe to assert main-actor isolation and call the handler synchronously.
final class CompassSensorManager: NSObject, @unchecked Sendable {

    private let locationManager = CLLocationManager()
    private var headingHandler: (@MainActor (CompassSample) -> Void)?

    var isAvailable: Bool { CLLocationManager.headingAvailable() }

    func startUpdates(handler: @escaping @MainActor (CompassSample) -> Void) {
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
        let sample = CompassSample(
            magneticHeading: newHeading.magneticHeading,
            trueHeading:     newHeading.trueHeading >= 0 ? newHeading.trueHeading : nil,
            accuracy:        newHeading.headingAccuracy
        )
        let handler = headingHandler
        MainActor.assumeIsolated { handler?(sample) }
    }
}

#else

/// Stub for non-iOS platforms. Compass is unavailable. :/
final class CompassSensorManager: @unchecked Sendable {
    var isAvailable: Bool { false }
    func startUpdates(handler: @escaping @MainActor (CompassSample) -> Void) {}
    func stopUpdates() {}
}

#endif
