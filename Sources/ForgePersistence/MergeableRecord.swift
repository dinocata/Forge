//
//  MergeableRecord.swift
//  ForgePersistence
//
//  Created by Dino Catalinac on 07.08.2026.
//

import ForgeCore
import Foundation
import SwiftData

/// A record that absorbs a domain value in place instead of being replaced by one.
///
/// Rebuilding a record from `init(from:)` is simple, but it destroys the row.
/// Anything the record owns that the domain type does not carry has to be
/// carried across by hand, and every child is deleted and reinserted along with
/// it — even when nothing about them changed. ``absorb(_:ordinal:)`` is the
/// alternative: the row survives, so there is nothing to carry over, and only
/// the fields that actually differ are written.
public protocol MergeableRecord: PersistentModel, DomainRepresentable where DomainType: Identifiable {

    /// Which stored column carries this record's identity.
    ///
    /// The record has to name it, because only the record knows which of its
    /// columns the domain value's identity was written to — often not an `id`
    /// at all, but the natural key of the thing it describes.
    var mergeKey: DomainType.ID { get }

    /// Creates a record for a value at a position within its parent's collection.
    init(from domain: DomainType, ordinal: Int)

    /// Takes on `domain`'s values without changing this record's row.
    func absorb(_ domain: DomainType, ordinal: Int)
}

public extension Array where Element: MergeableRecord {

    /// Reconciles this collection against `values`, in place.
    ///
    /// A record whose value survives absorbs it and keeps its row, a value with
    /// no record gets a new one, and a record whose value is gone is deleted.
    /// Position within the collection is passed to each record as an ordinal,
    /// because SwiftData does not preserve relationship order — the records that
    /// have an order store it.
    ///
    /// Removed records are deleted explicitly rather than left to the cascade
    /// rule: a cascade fires when the *parent* is deleted, so dropping a child
    /// from a relationship only disassociates it and would leave the row behind
    /// as an orphan.
    mutating func reconcile(
        with values: some Collection<Element.DomainType>,
        in modelContext: ModelContext?
    ) {
        let existingRecords = asIdentifiedDictionary(by: \.mergeKey)
        let survivingKeys = Set(values.map(\.id))

        let reconciled = values.enumerated().map { ordinal, value in
            guard let record = existingRecords[value.id] else {
                return Element(from: value, ordinal: ordinal)
            }

            record.absorb(value, ordinal: ordinal)
            return record
        }

        // A merge key is a unique column, so no surviving key can leave a second
        // row behind unmatched.
        let orphans = filter { !survivingKeys.contains($0.mergeKey) }

        self = reconciled
        orphans.forEach { modelContext?.delete($0) }
    }
}
