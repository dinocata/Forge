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

// MARK: - Collections

private enum Kind: String, Codable, CodableDefaultValue {
    case barbell
    case dumbbell

    static let defaultCodableValue = Kind.barbell
}

private struct Inventory: Codable, Equatable {
    @CodableDefault
    var kinds: [Kind]

    @CodableDefault
    var owned: Set<Kind>?

    init(kinds: [Kind] = [], owned: Set<Kind>? = nil) {
        self.kinds = kinds
        self.owned = owned
    }
}

private func inventory(_ json: String) throws -> Inventory {
    try JSONDecoder().decode(Inventory.self, from: Data(json.utf8))
}

/// The reason this exists: stored data written by a build that knew a value this one does not must
/// cost that value alone, not every value beside it.
@Test func codableDefaultKeepsTheElementsItCanRead() throws {
    #expect(try inventory(#"{"kinds":["barbell","jetpack","dumbbell"]}"#).kinds == [.barbell, .dumbbell])
    #expect(try inventory(#"{"owned":["jetpack","dumbbell"]}"#).owned == [.dumbbell])
}

/// Dropping every element is not the same as never having been given any, and an optional
/// collection has to keep that difference: the user did answer, unreadably.
@Test func codableDefaultDistinguishesAnUnreadableCollectionFromAMissingOne() throws {
    #expect(try inventory(#"{"owned":["jetpack"]}"#).owned == [])
    #expect(try inventory("{}").owned == nil)
    #expect(try inventory(#"{"owned":null}"#).owned == nil)
}

@Test func codableDefaultStillFallsBackForAMissingCollection() throws {
    #expect(try inventory("{}").kinds.isEmpty)
}

@Test func codableDefaultRoundTripsCollections() throws {
    let inventory = Inventory(kinds: [.barbell], owned: [.dumbbell])

    let data = try JSONEncoder().encode(inventory)

    #expect(try JSONDecoder().decode(Inventory.self, from: data) == inventory)
}

/// Leniency is for the members, not the shape: a collection where an object was expected is a
/// different kind of wrong and must still fail.
@Test func codableDefaultDoesNotHideAMalformedCollection() {
    #expect(throws: DecodingError.self) {
        try inventory(#"{"kinds":{"a":1}}"#)
    }
}
