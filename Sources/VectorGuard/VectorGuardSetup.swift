//
//  VectorGuardSetup.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 13/05/2026.
//

import Foundation

// MARK: - One-call

public extension VectorGuard {
    
    @discardableResult
    static func configure(configuration: VectorGuardConfiguration = VectorGuardConfiguration(),
                          delegate: VectorGuardDelegate? = nil,
                          autoStart: Bool = true ) -> VectorGuard {
        let instance = VectorGuard.shared
        instance.configuration = configuration
        instance.delegate = delegate
        if autoStart {
            instance.startMonitoring()
        }
        return instance
    }
}
