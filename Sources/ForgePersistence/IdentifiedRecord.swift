//
//  IdentifiedRecord.swift
//  ForgePersistence
//
//  Created by Dino Catalinac on 07.08.2026.
//

import Foundation
import SwiftData

/// A record a repository stores and looks up in its own right, rather than one
/// reached through the record that owns it.
///
/// Child records deliberately cannot conform: many carry no stored identity to
/// look them up by, and none of them is ever written on its own — they are
/// reconciled through their parent by ``MergeableRecord``. Drawing the line here
/// means ``ModelContext/upsert(_:)`` cannot be reached for a child by mistake,
/// rather than that being a rule someone has to remember.
public protocol IdentifiedRecord: PersistentModel, DomainRepresentable {

    /// Finds the stored record that holds `domain`, if there is one.
    ///
    /// This is deliberately the only requirement, and it is phrased as a lookup
    /// rather than as an identity to extract. A record whose key is the domain
    /// value's `id` answers it by forwarding to that; a singleton answers it with
    /// its fixed key, without having to invent an `id` on a domain value that
    /// has none. Both are one line, and neither needs the protocol to know which
    /// kind it is dealing with.
    static func fetchDescriptor(for domain: DomainType) -> FetchDescriptor<Self>
}

public extension ModelContext {

    /// Updates the stored record holding `domain`, or inserts one.
    ///
    /// Updating in place is what keeps the row — and everything hanging off it
    /// that the domain type does not carry — intact. Only a genuinely new value
    /// is inserted.
    ///
    /// **Deliberately does not save.** A repository built as a single
    /// `@ModelActor` with one context relies on operations that span several
    /// entities committing together. Saving here would quietly split every one
    /// of those into separate transactions, so the decision of when to commit
    /// stays with the caller.
    @discardableResult
    func upsert<Record: IdentifiedRecord>(_ domain: Record.DomainType) throws -> Record {
        guard var existingRecord = try fetch(Record.fetchDescriptor(for: domain)).first else {
            let record = Record(from: domain)
            insert(record)
            return record
        }

        existingRecord.update(with: domain)
        return existingRecord
    }
}
