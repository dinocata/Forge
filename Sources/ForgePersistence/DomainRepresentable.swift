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

    /// Takes on `domain`'s values in place, without replacing the stored record.
    ///
    /// Deliberately has no default implementation. A conformer that says nothing
    /// would otherwise fall back to delete-and-reinsert, which destroys the row:
    /// anything the record owns that the domain type does not carry — a
    /// relationship, a creation date — is silently lost, and every child record
    /// is deleted and reinserted along with it. That is a decision worth making
    /// on purpose, so the compiler asks for one.
    mutating func update(with domain: DomainType)
}
