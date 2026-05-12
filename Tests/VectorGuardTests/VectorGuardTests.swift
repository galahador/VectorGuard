//
//  VectorGuardTests.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation
import Testing
@testable import VectorGuard

// MARK: - SensorVector Tests

@Suite("SensorVector")
struct SensorVectorTests {

    @Test("zero vector has magnitude 0")
    func zeroMagnitude() {
        #expect(SensorVector.zero.magnitude == 0)
    }

    @Test("unit vector along X has magnitude 1")
    func unitX() {
        let v = SensorVector(x: 1, y: 0, z: 0)
        #expect(abs(v.magnitude - 1.0) < 1e-10)
    }

    @Test("3-4-5 pythagorean triple")
    func pythagoras() {
        let v = SensorVector(x: 3, y: 4, z: 0)
        #expect(abs(v.magnitude - 5.0) < 1e-10)
    }

    @Test("equality compares all components")
    func equality() {
        let a = SensorVector(x: 1, y: 2, z: 3)
        let b = SensorVector(x: 1, y: 2, z: 3)
        let c = SensorVector(x: 1, y: 2, z: 0)
        #expect(a == b)
        #expect(a != c)
    }
}

// MARK: - SignalBuffer Tests

@Suite("SignalBuffer")
struct SignalBufferTests {

    @Test("empty buffer has count 0")
    func emptyBuffer() {
        let buf = SignalBuffer(capacity: 4)
        #expect(buf.count == 0)
        #expect(buf.isEmpty)
        #expect(!buf.isFull)
        #expect(buf.average == 0)
    }

    @Test("buffer fills and reports isFull")
    func fillBuffer() {
        var buf = SignalBuffer(capacity: 3)
        buf.push(1); buf.push(2); buf.push(3)
        #expect(buf.isFull)
        #expect(buf.count == 3)
    }

    @Test("average of 1 2 3 is 2")
    func average() {
        var buf = SignalBuffer(capacity: 3)
        buf.push(1); buf.push(2); buf.push(3)
        #expect(abs(buf.average - 2.0) < 1e-10)
    }

    @Test("ring wraps and discards oldest value")
    func ringWrap() {
        var buf = SignalBuffer(capacity: 3)
        buf.push(10); buf.push(20); buf.push(30)
        buf.push(40)                               // overwrites 10
        let vals = buf.values
        #expect(vals == [20, 30, 40])
        #expect(buf.count == 3)
    }
}

// MARK: - MotionState Tests

@Suite("MotionState")
struct MotionStateTests {

    @Test("coarse equality ignores associated values")
    func coarseEquality() {
        let a = MotionState.moving(intensity: 0.5)
        let b = MotionState.moving(intensity: 9.9)
        #expect(a == b)
    }

    @Test("different cases are not equal")
    func differentCases() {
        #expect(MotionState.idle != MotionState.jiggling)
        #expect(MotionState.idle != MotionState.moving(intensity: 0))
    }

    @Test("description is non-empty for all cases")
    func descriptions() {
        let states: [MotionState] = [
            .idle,
            .moving(intensity: 1.23),
            .rapidMovement(vector: .zero),
            .jiggling,
        ]
        for state in states {
            #expect(!state.description.isEmpty)
        }
    }
}

// MARK: - MotionAnalyzer Tests

@Suite("MotionAnalyzer")
struct MotionAnalyzerTests {

    // Helpers — build synthetic samples
    private func accel(_ mag: Double, ts: TimeInterval) -> AccelerometerSample {
        AccelerometerSample(
            userAcceleration: SensorVector(x: mag, y: 0, z: 0),
            gravity: SensorVector(x: 0, y: 0, z: -1),
            timestamp: ts
        )
    }

    private func gyro(_ mag: Double, ts: TimeInterval) -> GyroscopeSample {
        GyroscopeSample(
            rotationRate: SensorVector(x: mag, y: 0, z: 0),
            timestamp: ts
        )
    }

    private func quietGyro(ts: TimeInterval) -> GyroscopeSample {
        gyro(0, ts: ts)
    }

    @Test("starts in idle state")
    @MainActor
    func initialState() {
        let analyzer = MotionAnalyzer(configuration: VectorGuardConfiguration())
        #expect(analyzer.currentState == .idle)
    }

    @Test("transitions to moving after sustained acceleration")
    @MainActor
    func transitionsToMoving() async {
        var config = VectorGuardConfiguration()
        config.movementThreshold = 0.1
        config.movementConfirmationSamples = 3

        let analyzer = MotionAnalyzer(configuration: config)
        var events: [VectorGuardEvent] = []
        analyzer.onEvent = { events.append($0) }

        for i in 0..<5 {
            analyzer.process(
                accelerometer: accel(0.5, ts: Double(i) * 0.05),
                gyroscope: quietGyro(ts: Double(i) * 0.05)
            )
        }

        #expect(analyzer.currentState == .moving(intensity: 0))  // coarse equality
        #expect(events.contains(where: { if case .devicePickedUp = $0 { true } else { false } }))
    }

    @Test("emits accelerationSpike for high-magnitude sample")
    @MainActor
    func rapidMovementSpike() async {
        var config = VectorGuardConfiguration()
        config.rapidMovementThreshold = 1.0
        config.rapidMovementDebounce  = 0.0

        let analyzer = MotionAnalyzer(configuration: config)
        var events: [VectorGuardEvent] = []
        analyzer.onEvent = { events.append($0) }

        analyzer.process(
            accelerometer: accel(2.0, ts: 0),
            gyroscope: quietGyro(ts: 0)
        )

        #expect(events.contains(where: {
            if case .accelerationSpike = $0 { true } else { false }
        }))
        #expect(analyzer.currentState == .rapidMovement(vector: .zero))  // coarse equality
    }
}
