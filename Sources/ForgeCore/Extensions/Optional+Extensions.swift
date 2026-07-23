//
//  Optional+Extensions.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//

import Foundation

public protocol AnyOptional {
    var isSome: Bool { get }
    var isNone: Bool { get }
}

extension Optional: AnyOptional {
    public var isSome: Bool { self != nil }
    public var isNone: Bool { self == nil }

    /// Warning: Use with caution and only when you are sure that the value
    /// will never be nil. Useful when you don't want to manually suppress
    /// force unwrap Swiftlint rule.
    public var forceUnwrap: Wrapped {
        guard let self else {
            fatalError("Value is nil!")
        }
        return self
    }
}

extension Optional where Wrapped == String {
    public var isEmptyOrNil: Bool {
        self?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
    }
}

extension Optional where Wrapped: Collection {
    public var isEmptyOrNil: Bool {
        self?.isEmpty ?? true
    }
}
