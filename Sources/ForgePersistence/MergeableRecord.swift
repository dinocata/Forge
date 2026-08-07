//
//  MergeableRecord.swift
//  ForgePersistence
//
//  Created by Dino Catalinac on 07.08.2026.
//

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
public protocol MergeableRecord: PersistentModel, DomainRepresentable {

    /// What a record and a domain value are matched on while reconciling a collection.
    ///
    /// Not always the record's own `id`. A leaf record often has no identity
    /// beyond the thing it describes, which is usually what its domain type uses
    /// for identity too.
    associatedtype MergeKey: Hashable

    /// This record's identity within its parent's collection.
    var mergeKey: MergeKey { get }

    /// The identity a domain value claims within its parent's collection.
    static func mergeKey(for domain: DomainType) -> MergeKey

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
        with values: some Sequence<Element.DomainType>,
        in modelContext: ModelContext?
    ) {
        let recordsByKey = Dictionary(map { ($0.mergeKey, $0) }, uniquingKeysWith: { first, _ in first })
        var reusedIDs: Set<PersistentIdentifier> = []
        var reconciled: [Element] = []

        for (ordinal, value) in values.enumerated() {
            guard let record = recordsByKey[Element.mergeKey(for: value)] else {
                reconciled.append(Element(from: value, ordinal: ordinal))
                continue
            }

            record.absorb(value, ordinal: ordinal)
            reusedIDs.insert(record.persistentModelID)
            reconciled.append(record)
        }

        // Computed against the collection as it still stands, and by row rather
        // than by merge key, so a duplicate key cannot leave a row undeleted.
        let orphans = filter { !reusedIDs.contains($0.persistentModelID) }
        self = reconciled
        orphans.forEach { modelContext?.delete($0) }
    }
}
