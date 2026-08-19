// Created by Dino Catalinac on 19.08.2026.

import Testing
@testable import ForgeCore

private struct Entry: Identifiable, Equatable {
    let id: Int
    let name: String
}

@Test func identifiedIfUniqueKeepsOrderWhenEveryIdentityDiffers() throws {
    let entries = [Entry(id: 1, name: "a"), Entry(id: 2, name: "b"), Entry(id: 3, name: "c")]

    let identified = try #require(entries.identifiedIfUnique)

    #expect(identified.elements == entries)
}

/// The reason this exists: `asIdentifiedArray` would *trap* on the same input,
/// so it cannot be used on anything decoded from outside the app. Deliberately
/// not asserted here — the alternative crashes the test process rather than
/// failing it.
@Test func identifiedIfUniqueRefusesARepeatedIdentity() {
    let entries = [Entry(id: 1, name: "a"), Entry(id: 2, name: "b"), Entry(id: 1, name: "c")]

    #expect(entries.identifiedIfUnique == nil)
}

/// A repeat anywhere is refused, not just an adjacent one.
@Test func identifiedIfUniqueRefusesARepeatAcrossTheSequence() {
    let entries = [Entry(id: 1, name: "a"), Entry(id: 1, name: "b")]

    #expect(entries.identifiedIfUnique == nil)
}

@Test func identifiedIfUniqueAcceptsAnEmptySequence() throws {
    let identified = try #require([Entry]().identifiedIfUnique)

    #expect(identified.isEmpty)
}
