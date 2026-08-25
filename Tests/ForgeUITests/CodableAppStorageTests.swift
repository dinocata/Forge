// Created by Dino Catalinac on 25.08.2026.

import Foundation
import Testing
@testable import ForgeUI

@MainActor
struct CodableAppStorageTests {
    @Test func readsAndWritesCodableValue() throws {
        let fixture = try makeUserDefaults()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.suiteName) }
        let storage = CodableAppStorage(
            wrappedValue: Settings.fallback,
            "settings",
            store: fixture.defaults
        )

        #expect(storage.wrappedValue == .fallback)

        storage.wrappedValue = .init(isEnabled: true, count: 3)

        let restored = CodableAppStorage(
            wrappedValue: Settings.fallback,
            "settings",
            store: fixture.defaults
        )
        #expect(restored.wrappedValue == .init(isEnabled: true, count: 3))
    }

    @Test func projectedBindingPersistsChanges() throws {
        let fixture = try makeUserDefaults()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.suiteName) }
        let storage = CodableAppStorage(
            wrappedValue: Settings.fallback,
            "settings",
            store: fixture.defaults
        )

        storage.projectedValue.wrappedValue = .init(isEnabled: true, count: 1)

        #expect(storage.wrappedValue == .init(isEnabled: true, count: 1))
    }

    @Test func malformedStoredDataUsesDefaultValue() throws {
        let fixture = try makeUserDefaults()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.suiteName) }
        fixture.defaults.set(Data("invalid".utf8), forKey: "settings")

        let storage = CodableAppStorage(
            wrappedValue: Settings.fallback,
            "settings",
            store: fixture.defaults
        )

        #expect(storage.wrappedValue == .fallback)
    }

    private func makeUserDefaults() throws -> (defaults: UserDefaults, suiteName: String) {
        let suiteName = "CodableAppStorageTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }
}

private struct Settings: Codable, Equatable, Sendable {
    static let fallback = Self(isEnabled: false, count: 0)

    let isEnabled: Bool
    let count: Int
}
