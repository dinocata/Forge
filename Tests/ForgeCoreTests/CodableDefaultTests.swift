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

// MARK: - Optional values

private enum Channel: String, Codable, CodableDefaultValue {
    case email
    case push

    static let defaultCodableValue = Channel.email
}

private struct OptionalPreferences: Codable, Equatable {
    @CodableDefault
    var channel: Channel?

    init(channel: Channel?) {
        self.channel = channel
    }
}

/// The reason the optional overload exists: a value written by a newer build, or a case since
/// retired, must cost that one entry rather than the whole container it was stored in.
@Test func codableDefaultFallsBackForAnUndecodableOptionalValue() throws {
    let json = #"{"channel":"carrierPigeon"}"#

    let preferences = try JSONDecoder().decode(OptionalPreferences.self, from: Data(json.utf8))

    #expect(preferences.channel == nil)
}

@Test func codableDefaultFallsBackForAMissingOptionalValue() throws {
    let preferences = try JSONDecoder().decode(OptionalPreferences.self, from: Data("{}".utf8))

    #expect(preferences.channel == nil)
}

/// Falling back must not swallow a value that decodes perfectly well.
@Test func codableDefaultDecodesAStoredOptionalValue() throws {
    let json = #"{"channel":"push"}"#

    let preferences = try JSONDecoder().decode(OptionalPreferences.self, from: Data(json.utf8))

    #expect(preferences.channel == .push)
}

@Test func codableDefaultRoundTripsAnOptionalValue() throws {
    for preferences in [OptionalPreferences(channel: .push), OptionalPreferences(channel: nil)] {
        let data = try JSONEncoder().encode(preferences)

        #expect(try JSONDecoder().decode(OptionalPreferences.self, from: data) == preferences)
    }
}
