//
//  VectorGuard.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation

/// The primary entry point for the VectorGuard library.
///
/// VectorGuard continuously analyses accelerometer, gyroscope, and compass data
/// to detect motion patterns useful for anti-theft scenarios:
///
/// - **Idle / Moving** — is the device stationary or being carried?
/// - **Rapid movement** — was the device suddenly grabbed, dropped, or thrown?
/// - **Jiggling** — is someone shaking the device (e.g. trying to unlock it)?
/// - **Heading change** — was the device rotated significantly?
///
/// ## Subscribing to events (recommended — supports multiple subscribers)
///
/// Any number of independent parts of your app can subscribe simultaneously.
/// Each gets every event; cancelling one does not affect the others.
///
/// ```swift
/// VectorGuard.shared.startMonitoring()
///
/// // Alarm screen
/// Task {
///     for await event in VectorGuard.shared.subscribe() {
///         if case .devicePickedUp = event { triggerAlarm() }
///     }
/// }
///
/// // Logging service — independent subscription, same events
/// Task {
///     for await event in VectorGuard.shared.subscribe() {
///         logger.record(event)
///     }
/// }
/// ```
///
/// Streams finish automatically when ``stopMonitoring()`` is called,
/// or when the subscriber's `Task` is cancelled.
///
/// ## Single-delegate (simple cases)
///
/// ```swift
/// VectorGuard.shared.delegate = self   // only one object at a time
/// VectorGuard.shared.startMonitoring()
/// ```
///
/// > Note: VectorGuard requires no special Info.plist keys for motion or heading data. <---- Check this before realease! 
@MainActor
public final class VectorGuard {

    // MARK: - Singleton

    /// The shared VectorGuard instance.
    public static let shared = VectorGuard()

    // MARK: - Public API

    /// Detection thresholds and timing parameters.
    ///
    /// Changes take effect immediately, even while monitoring is active.
    public var configuration: VectorGuardConfiguration = VectorGuardConfiguration() {
        didSet { analyzer.configuration = configuration }
    }

    /// Optional single delegate for simple use cases where only one object needs events.
    ///
    /// For multiple independent subscribers use ``subscribe()`` instead.
    public weak var delegate: VectorGuardDelegate?

    /// The most recently inferred motion state.
    ///
    /// Reads directly from the analyzer 
    public var currentState: MotionState { analyzer.currentState }

    /// Whether the library is actively collecting sensor data.
    public private(set) var isMonitoring = false

    /// A point-in-time snapshot of everything VectorGuard knows.
    ///
    /// Each access returns an independent, immutable ``VectorGuardStatus`` value — safe to
    /// store, compare, or pass to other types without worrying about concurrent mutation.
    ///
    /// ```swift
    /// let status = VectorGuard.shared.status
    /// if status.isJiggling { triggerAlarm() }
    /// print(status.lastHeading ?? "no heading")
    /// ```
    public var status: VectorGuardStatus {
        VectorGuardStatus(
            isMonitoring:        isMonitoring,
            currentState:        currentState,
            lastAcceleration:    lastAcceleration,
            lastGyroscope:       lastGyroscope,
            lastHeading:         lastHeading,
            lastPressure:        lastPressure,
            lastRelativeAltitude: lastRelativeAltitude,
            lastEvent:           lastEvent,
            lastEventDate:       lastEventDate
        )
    }

    // MARK: - Live Sensor Readings

    /// Most recent user-acceleration vector (g). Updated on every sensor frame.
    public private(set) var lastAcceleration: SensorVector?

    /// Most recent rotation-rate vector (rad/s). Updated on every sensor frame.
    public private(set) var lastGyroscope: SensorVector?

    /// Most recent compass heading in degrees (0–360). Updated on every heading callback.
    public private(set) var lastHeading: Double?

    /// Most recent barometric pressure in kilopascals.
    public private(set) var lastPressure: Double?

    /// Relative altitude in metres since monitoring started.
    public private(set) var lastRelativeAltitude: Double?

    /// Altitude (metres) at which the last altitudeChanged event was emitted.
    private var lastEventAltitude: Double?

    /// Most recently emitted event.
    public private(set) var lastEvent: VectorGuardEvent?

    /// Wall-clock time of the most recently emitted event.
    public private(set) var lastEventDate: Date?

    // MARK: - Internal: Stream Subscribers

    /// Each event subscriber gets its own continuation keyed by a unique ID.
    private var subscribers: [UUID: AsyncStream<VectorGuardEvent>.Continuation] = [:]

    /// Each sensor-reading subscriber gets its own continuation keyed by a unique ID.
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

    /// Begin collecting and analysing sensor data.
    ///
    /// Calling this while already monitoring has no effect.
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        motionManager.startUpdates(interval: configuration.sensorUpdateInterval) { [weak self] accel, gyro in
            guard let self else { return }
            self.lastAcceleration = accel.userAcceleration
            self.lastGyroscope    = gyro.rotationRate
            self.analyzer.process(accelerometer: accel, gyroscope: gyro)
            let reading = SensorReading(
                acceleration:     accel.userAcceleration,
                gyroscope:        gyro.rotationRate,
                heading:          self.lastHeading,
                timestamp:        accel.timestamp,
                state:            self.currentState,
                pressure:         self.lastPressure,
                relativeAltitude: self.lastRelativeAltitude
            )
            for continuation in self.sensorSubscribers.values {
                continuation.yield(reading)
            }
        }

        if compassManager.isAvailable {
            compassManager.startUpdates { [weak self] heading in
                self?.lastHeading = heading
                self?.analyzer.process(heading: heading)
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

    /// Stop all sensor collection and finish all active event streams.
    ///
    /// `currentState` is preserved until the next ``startMonitoring()`` call.
    /// Calling this while not monitoring has no effect.
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

    /// Returns an `AsyncStream` that delivers every VectorGuard event to the caller.
    ///
    /// Multiple independent subscribers are fully supported — each receives every event
    /// without affecting one another. The stream ends when:
    /// - ``stopMonitoring()`` is called, or
    /// - the subscriber's `Task` is cancelled.
    ///
    /// ```swift
    /// Task {
    ///     for await event in VectorGuard.shared.subscribe() {
    ///         switch event {
    ///         case .devicePickedUp:  lockApp()
    ///         case .jiggling:        triggerAlert()
    ///         default:               break
    ///         }
    ///     }
    /// }
    /// ```
    public func subscribe() -> AsyncStream<VectorGuardEvent> {
        let id = UUID()
        let snapshotState = currentState
        // Capture the continuation synchronously so we can store it before any events fire.
        var localContinuation: AsyncStream<VectorGuardEvent>.Continuation?
        let stream = AsyncStream<VectorGuardEvent> { continuation in
            localContinuation = continuation
        }
        if let continuation = localContinuation {
            subscribers[id] = continuation
            // Late-subscriber replay: immediately deliver the current state so callers
            // that subscribe after startMonitoring() are never blind to ongoing motion.
            if isMonitoring && snapshotState != .idle {
                continuation.yield(.stateChanged(from: .idle, to: snapshotState))
            }
            continuation.onTermination = { [weak self] _ in
                // onTermination may be called from any thread — hop to MainActor to mutate state.
                Task { @MainActor [weak self] in
                    self?.subscribers.removeValue(forKey: id)
                }
            }
        }
        return stream
    }

    /// Returns an `AsyncStream` that delivers only events matching `predicate`.
    ///
    /// Built on top of ``subscribe()`` — inherits the same fan-out and lifecycle semantics.
    ///
    /// ```swift
    /// Task {
    ///     for await event in VectorGuard.shared.subscribe(where: { $0 == .devicePickedUp }) {
    ///         triggerAlarm()
    ///     }
    /// }
    /// ```
    public func subscribe(where predicate: @escaping @Sendable (VectorGuardEvent) -> Bool) -> AsyncStream<VectorGuardEvent> {
        let base = subscribe()
        return AsyncStream { continuation in
            Task {
                for await event in base where predicate(event) {
                    continuation.yield(event)
                }
                continuation.finish()
            }
        }
    }

    /// Returns an `AsyncStream` that delivers a ``SensorReading`` on every motion sensor frame.
    ///
    /// Use this when you need continuous access to raw sensor values — acceleration,
    /// gyroscope, heading, and the current motion state — rather than discrete events.
    /// Multiple independent callers are fully supported; each gets every frame.
    /// The stream ends when ``stopMonitoring()`` is called or the subscriber's `Task` is cancelled.
    ///
    /// ```swift
    /// Task {
    ///     for await reading in VectorGuard.shared.monitorSensors() {
    ///         print(String(format: "accel: %.2f g", reading.acceleration.magnitude))
    ///         print(String(format: "gyro:  %.2f rad/s", reading.gyroscope.magnitude))
    ///         print("heading:", reading.heading.map { "\($0)°" } ?? "n/a")
    ///         print("state:", reading.state)
    ///     }
    /// }
    /// ```
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

    /// Returns a throttled `AsyncStream` of ``SensorReading`` values.
    ///
    /// Frames arriving faster than `interval` seconds are dropped, keeping only
    /// the most recent one that falls outside the window. Useful for driving SwiftUI
    /// views where 20 Hz updates would cause unnecessary redraws.
    ///
    /// ```swift
    /// Task {
    ///     for await reading in VectorGuard.shared.monitorSensors(throttle: 0.1) { // 10 Hz
    ///         updateUI(reading)
    ///     }
    /// }
    /// ```
    public func monitorSensors(throttle interval: TimeInterval) -> AsyncStream<SensorReading> {
        let base = monitorSensors()
        return AsyncStream { continuation in
            Task {
                var lastTimestamp: TimeInterval = -.infinity
                for await reading in base {
                    if reading.timestamp - lastTimestamp >= interval {
                        continuation.yield(reading)
                        lastTimestamp = reading.timestamp
                    }
                }
                continuation.finish()
            }
        }
    }

    // MARK: - Private: Broadcasting

    private func broadcast(event: VectorGuardEvent) {
        // Drop any in-flight callbacks that arrived after stopMonitoring() was called.
        guard isMonitoring else { return }
        lastEvent     = event
        lastEventDate = Date()
        // Deliver to single delegate
        delegate?.vectorGuard(self, didDetect: event)
        // Deliver to every stream subscriber
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
