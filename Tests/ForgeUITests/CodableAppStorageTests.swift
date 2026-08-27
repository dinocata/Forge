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

    @Test func usesInjectedEncoderAndDecoder() throws {
        let fixture = try makeUserDefaults()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.suiteName) }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let storage = CodableAppStorage(
            wrappedValue: DatedSettings.fallback,
            "datedSettings",
            store: fixture.defaults,
            encoder: encoder,
            decoder: decoder
        )

        storage.wrappedValue = .fixture

        let data = try #require(fixture.defaults.data(forKey: "datedSettings"))
        #expect(String(decoding: data, as: UTF8.self).contains("1970-01-01"))
        #expect(storage.wrappedValue == .fixture)
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

private struct DatedSettings: Codable, Equatable, Sendable {
    static let fallback = Self(createdAt: .distantPast)
    static let fixture = Self(createdAt: Date(timeIntervalSince1970: 0))

    let createdAt: Date
}
