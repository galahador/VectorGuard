//
//  VectorGuardDelegate.swift
//  VectorGuard
//
//  Created by Petar Lemajic on 12/05/2026.
//

import Foundation

public protocol VectorGuardDelegate: AnyObject {
    func vectorGuard(_ guard: VectorGuard, didDetect event: VectorGuardEvent)
}
