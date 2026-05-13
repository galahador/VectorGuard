//
//  VectorGuardSetup.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 13/05/2026.
//

import Foundation

// MARK: - One-call

public extension VectorGuard {

    /// Configure and optionally start VectorGuard in a single call.
    ///
    /// Drop this into your `AppDelegate.application(_:didFinishLaunchingWithOptions:)` or
    /// SwiftUI `@main` `init()` to get everything running without boilerplate.
    ///
    /// ```swift
    /// // SwiftUI @main
    /// @main
    /// struct MyApp: App {
    ///     init() {
    ///         VectorGuard.configure(autoStart: true)
    ///     }
    ///     var body: some Scene { WindowGroup { ContentView() } }
    /// }
    ///
    /// // UIKit AppDelegate
    /// func application(_ application: UIApplication,
    ///                  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    ///     VectorGuard.configure(
    ///         configuration: VectorGuardConfiguration(rapidMovementThreshold: 2.5),
    ///         delegate: self,
    ///         autoStart: true
    ///     )
    ///     return true
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - configuration: Detection thresholds and timing. Defaults to ``VectorGuardConfiguration/default``.
    ///   - delegate: Optional single delegate for simple event handling.
    ///   - autoStart: When `true`, ``startMonitoring()`` is called immediately. Defaults to `true`.
    @discardableResult
    static func configure(
        configuration: VectorGuardConfiguration = VectorGuardConfiguration(),
        delegate: VectorGuardDelegate? = nil,
        autoStart: Bool = true
    ) -> VectorGuard {
        let instance = VectorGuard.shared
        instance.configuration = configuration
        instance.delegate = delegate
        if autoStart {
            instance.startMonitoring()
        }
        return instance
    }
}
