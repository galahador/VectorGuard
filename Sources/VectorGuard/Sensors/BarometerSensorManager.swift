//
//  BarometerSensorManager.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 13/05/2026.
//

import Foundation

#if os(iOS)

import CoreMotion

final class BarometerSensorManager: @unchecked Sendable {

    private let altimeter = CMAltimeter()

    var isAvailable: Bool { CMAltimeter.isRelativeAltitudeAvailable() }

    func startUpdates(handler: @escaping @MainActor (Double, Double) -> Void) {
        guard isAvailable else { return }
        altimeter.startRelativeAltitudeUpdates(to: .main) { data, error in
            guard let data, error == nil else { return }
            let pressure         = data.pressure.doubleValue          // kPa
            let relativeAltitude = data.relativeAltitude.doubleValue  // metres
            // CMAltimeter guarantees callbacks on `.main` arrive on the main thread, in
            // order — safe to assert main-actor isolation and call synchronously.
            MainActor.assumeIsolated { handler(pressure, relativeAltitude) }
        }
    }

    func stopUpdates() {
        altimeter.stopRelativeAltitudeUpdates()
    }
}

#else

final class BarometerSensorManager: @unchecked Sendable {
    var isAvailable: Bool { false }
    func startUpdates(handler: @escaping @MainActor (Double, Double) -> Void) {}
    func stopUpdates() {}
}

#endif
