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
/// > Note: VectorGuard requires no special Info.plist keys for motion or heading data.
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
    public private(set) var currentState: MotionState = .idle

    /// Whether the library is actively collecting sensor data.
    public private(set) var isMonitoring = false

    // MARK: - Internal: Stream Subscribers

    /// Each subscriber gets its own continuation keyed by a unique ID.
    private var subscribers: [UUID: AsyncStream<VectorGuardEvent>.Continuation] = [:]

    // MARK: - Internal: Sensor Components

    private let motionManager  = MotionSensorManager()
    private let compassManager = CompassSensorManager()
    private lazy var analyzer  = MotionAnalyzer(configuration: configuration)

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
            self?.analyzer.process(accelerometer: accel, gyroscope: gyro)
        }

        compassManager.startUpdates { [weak self] heading in
            self?.analyzer.process(heading: heading)
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
        // Capture the continuation synchronously so we can store it before any events fire.
        var localContinuation: AsyncStream<VectorGuardEvent>.Continuation?
        let stream = AsyncStream<VectorGuardEvent> { continuation in
            localContinuation = continuation
        }
        if let continuation = localContinuation {
            subscribers[id] = continuation
            continuation.onTermination = { [weak self] _ in
                // onTermination may be called from any thread — hop to MainActor to mutate state.
                Task { @MainActor [weak self] in
                    self?.subscribers.removeValue(forKey: id)
                }
            }
        }
        return stream
    }

    // MARK: - Private: Broadcasting

    private func broadcast(event: VectorGuardEvent) {
        // Drop any in-flight callbacks that arrived after stopMonitoring() was called.
        guard isMonitoring else { return }
        if case .stateChanged(_, let newState) = event {
            currentState = newState
        }
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
    }
}
