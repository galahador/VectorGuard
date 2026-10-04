//
//  VectorGuard.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation

@MainActor
public final class VectorGuard {

    // MARK: - Singleton
    public static let shared = VectorGuard()

    // MARK: - Public API
    public var configuration: VectorGuardConfiguration = VectorGuardConfiguration() {
        didSet { analyzer.configuration = configuration }
    }

    public weak var delegate: VectorGuardDelegate?

    public var currentState: MotionState { analyzer.currentState }

    public var motionConfidence: Double { analyzer.motionConfidence }

    public var orientation: DeviceOrientation { analyzer.currentOrientation }

    public var idleSurfaceState: IdleSurfaceState { analyzer.idleSurfaceState }

    public private(set) var isMonitoring = false

    public var status: VectorGuardStatus {
        VectorGuardStatus(
            isMonitoring:        isMonitoring,
            currentState:        currentState,
            motionConfidence:    motionConfidence,
            orientation:         orientation,
            idleSurfaceState:    idleSurfaceState,
            lastAcceleration:    lastAcceleration,
            lastGyroscope:       lastGyroscope,
            lastAttitude:        lastAttitude,
            lastHeading:         lastHeading,
            lastTrueHeading:     lastTrueHeading,
            lastHeadingAccuracy: lastHeadingAccuracy,
            lastPressure:        lastPressure,
            lastRelativeAltitude: lastRelativeAltitude,
            lastEvent:           lastEvent,
            lastEventDate:       lastEventDate
        )
    }

    // MARK: - Live Sensor Readings
    
    public private(set) var lastAcceleration: SensorVector?

    public private(set) var lastGyroscope: SensorVector?

    public private(set) var lastAttitude: DeviceAttitude?

    public private(set) var lastHeading: Double?

    public private(set) var lastTrueHeading: Double?

    public private(set) var lastHeadingAccuracy: Double?

    public private(set) var lastPressure: Double?

    public private(set) var lastRelativeAltitude: Double?

    private var lastEventAltitude: Double?

    public private(set) var lastEvent: VectorGuardEvent?

    public private(set) var lastEventDate: Date?

    // MARK: - Internal: Stream Subscribers

    private var subscribers: [UUID: AsyncStream<VectorGuardEvent>.Continuation] = [:]

    private var sensorSubscribers: [UUID: AsyncStream<SensorReading>.Continuation] = [:]

    // MARK: - Internal: Sensor Components
    private let motionManager    = MotionSensorManager()
    private let compassManager   = CompassSensorManager()
    private let barometerManager = BarometerSensorManager()
    private lazy var analyzer    = MotionAnalyzer(configuration: configuration)

    // MARK: - Init

    private init() {
        analyzer.onEvent = { [weak self] event in
            self?.broadcast(event: event)
        }
    }

    // MARK: - Control
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        motionManager.startUpdates(interval: configuration.sensorUpdateInterval) { [weak self] accel, gyro, attitude in
            guard let self else { return }
            self.lastAcceleration = accel.userAcceleration
            self.lastGyroscope    = gyro.rotationRate
            self.lastAttitude     = attitude
            self.analyzer.process(accelerometer: accel, gyroscope: gyro, attitude: attitude)
            let reading = SensorReading(
                acceleration:     accel.userAcceleration,
                gyroscope:        gyro.rotationRate,
                attitude:         attitude,
                heading:          self.lastHeading,
                trueHeading:      self.lastTrueHeading,
                headingAccuracy:  self.lastHeadingAccuracy,
                timestamp:        accel.timestamp,
                state:            self.currentState,
                motionConfidence: self.motionConfidence,
                orientation:      self.orientation,
                idleSurfaceState: self.idleSurfaceState,
                pressure:         self.lastPressure,
                relativeAltitude: self.lastRelativeAltitude
            )
            for continuation in self.sensorSubscribers.values {
                continuation.yield(reading)
            }
        }

        if compassManager.isAvailable {
            compassManager.startUpdates { [weak self] sample in
                guard let self else { return }
                self.lastHeading         = sample.magneticHeading
                self.lastTrueHeading     = sample.trueHeading
                self.lastHeadingAccuracy = sample.accuracy
                self.analyzer.process(heading: sample.magneticHeading)
            }
        }

        if barometerManager.isAvailable {
            barometerManager.startUpdates { [weak self] pressure, altitude in
                guard let self else { return }
                self.lastPressure         = pressure
                self.lastRelativeAltitude = altitude
                let base  = self.lastEventAltitude ?? altitude
                let delta = altitude - base
                if abs(delta) >= self.configuration.altitudeChangeThreshold {
                    self.lastEventAltitude = altitude
                    self.broadcast(event: .altitudeChanged(delta: delta, pressure: pressure))
                }
            }
        }
    }

    public func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        motionManager.stopUpdates()
        compassManager.stopUpdates()
        barometerManager.stopUpdates()
        lastEventAltitude = nil
        finishAllStreams()
    }

    // MARK: - Streaming API
    public func subscribe() -> AsyncStream<VectorGuardEvent> {
        let id = UUID()
        // Capture the continuation synchronously so we can store it before any events fire.
        var localContinuation: AsyncStream<VectorGuardEvent>.Continuation?
        let stream = AsyncStream<VectorGuardEvent> { continuation in
            localContinuation = continuation
        }
        if let continuation = localContinuation {
            subscribers[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.subscribers.removeValue(forKey: id)
                }
            }
        }
        return stream
    }

    public func subscribe(where predicate: @escaping @Sendable (VectorGuardEvent) -> Bool) -> AsyncStream<VectorGuardEvent> {
        let base = subscribe()
        return AsyncStream { continuation in
            let relay = Task {
                for await event in base where predicate(event) {
                    if Task.isCancelled { break }
                    continuation.yield(event)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in relay.cancel() }
        }
    }

    public func monitorSensors() -> AsyncStream<SensorReading> {
        let id = UUID()
        var localContinuation: AsyncStream<SensorReading>.Continuation?
        let stream = AsyncStream<SensorReading> { continuation in
            localContinuation = continuation
        }
        if let continuation = localContinuation {
            sensorSubscribers[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.sensorSubscribers.removeValue(forKey: id)
                }
            }
        }
        return stream
    }

    public func monitorSensors(throttle interval: TimeInterval) -> AsyncStream<SensorReading> {
        let base = monitorSensors()
        return AsyncStream { continuation in
            let relay = Task {
                var lastTimestamp: TimeInterval = -.infinity
                for await reading in base {
                    if Task.isCancelled { break }
                    if reading.timestamp - lastTimestamp >= interval {
                        continuation.yield(reading)
                        lastTimestamp = reading.timestamp
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in relay.cancel() }
        }
    }

    // MARK: - Private: Broadcasting

    private func broadcast(event: VectorGuardEvent) {
        guard isMonitoring else { return }
        lastEvent     = event
        lastEventDate = Date()
        delegate?.vectorGuard(self, didDetect: event)
        for continuation in subscribers.values {
            continuation.yield(event)
        }
    }

    private func finishAllStreams() {
        subscribers.values.forEach { $0.finish() }
        subscribers.removeAll()
        sensorSubscribers.values.forEach { $0.finish() }
        sensorSubscribers.removeAll()
    }
}
