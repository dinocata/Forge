// Created by Dino Catalinac on 25.08.2026.

import Foundation
import Testing
@testable import ForgeCore

private struct Preferences: Codable, Equatable {
    @CodableDefault
    var newChannelEnabled: Bool

    @CodableDefault
    var launchCount: Int

    @CodableDefault
    var tags: [String]

    init(newChannelEnabled: Bool, launchCount: Int = 0, tags: [String] = []) {
        self.newChannelEnabled = newChannelEnabled
        self.launchCount = launchCount
        self.tags = tags
    }
}

@Test func codableDefaultUsesFallbackWhenKeyIsMissing() throws {
    let preferences = try JSONDecoder().decode(Preferences.self, from: Data("{}".utf8))

    #expect(preferences.newChannelEnabled == false)
    #expect(preferences.launchCount == 0)
    #expect(preferences.tags.isEmpty)
}

@Test func codableDefaultDecodesStoredValue() throws {
    let json = #"{"newChannelEnabled":true}"#

    let preferences = try JSONDecoder().decode(Preferences.self, from: Data(json.utf8))

    #expect(preferences.newChannelEnabled == true)
}

@Test func codableDefaultRoundTripsWrappedValue() throws {
    let preferences = Preferences(newChannelEnabled: true, launchCount: 3, tags: ["strength"])

    let data = try JSONEncoder().encode(preferences)

    #expect(try JSONDecoder().decode(Preferences.self, from: data) == preferences)
}

@Test func codableDefaultDoesNotHideInvalidStoredValue() {
    let json = #"{"newChannelEnabled":"yes"}"#

    #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(Preferences.self, from: Data(json.utf8))
    }
}
