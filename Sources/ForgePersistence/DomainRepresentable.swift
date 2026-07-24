//
//  DomainRepresentable.swift
//  AppCore
//
//  Created by Dino Catalinac on 04.02.2026..
//

import Foundation

public protocol DomainRepresentable {
    associatedtype DomainType

    var toDomain: DomainType { get }
    init(from domain: DomainType)
    /// Updates the receiver with the given domain value. Returns `true` if the update was applied;
    /// `false` if the type does not support in-place update (e.g. default impl). Callers can fall back to delete+insert when `false`.
    mutating func update(with domain: DomainType) -> Bool
}

public extension DomainRepresentable {

    /// Default: no in-place update; callers (e.g. `cache`) will replace by delete+insert.
    mutating func update(with domain: DomainType) -> Bool {
        false
    }
}
