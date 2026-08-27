// Created by Dino Catalinac on 27.08.2026.

import Foundation
import Testing
@testable import ForgePersistence

struct UserDefaultsCodableTests {
    @Test func usesInjectedEncoderAndDecoder() throws {
        let fixture = try makeUserDefaults()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.suiteName) }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        #expect(
            fixture.defaults.storeCodable(
                DatedValue.fixture,
                forKey: "datedValue",
                encoder: encoder,
                decoder: decoder
            )
        )

        let data = try #require(fixture.defaults.data(forKey: "datedValue"))
        #expect(String(decoding: data, as: UTF8.self).contains("1970-01-01"))
        let restored: DatedValue? = fixture.defaults.getCodable("datedValue", decoder: decoder)
        #expect(restored == .fixture)
    }

    private func makeUserDefaults() throws -> (defaults: UserDefaults, suiteName: String) {
        let suiteName = "UserDefaultsCodableTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }
}

private struct DatedValue: Codable, Equatable {
    static let fixture = Self(createdAt: Date(timeIntervalSince1970: 0))

    let createdAt: Date
}
