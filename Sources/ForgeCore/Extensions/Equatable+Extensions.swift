//
//  Equatable+Extensions.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//

import Foundation

public extension Equatable {

    /// Checks if the current value is one of the provided values.
    func isOneOf(_ values: Self...) -> Bool {
        values.contains(self)
    }

    /// Compares the current value with another Equatable value of
    /// potentially different type. Useful when working with type-erased
    /// values (e.g., `any Equatable`) where you need to safely compare
    /// generic values without knowing their concrete types at compile time.
    func isEqualTo(_ rhs: any Equatable) -> Bool {
        guard let other = rhs as? Self else {
            return false
        }
        return self == other
    }
}
