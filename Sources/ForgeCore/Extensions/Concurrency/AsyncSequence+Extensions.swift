//
//  AsyncSequence+Extensions.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//

import Foundation

public extension AsyncSequence {

    /// Converts an `AsyncSequence` into a regular array. Make sure to only
    /// call this on finite async sequences.
    func collect() async rethrows -> [Element] where Self: Sendable, Element: Sendable {
        try await reduce(into: [], { $0.append($1) })
    }
}
