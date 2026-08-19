// Created by Dino Catalinac on 19.08.2026.

import Foundation
import Testing
@testable import ForgeCore

private struct Item: Codable, Equatable {
    let id: Int
    let name: String
}

private struct Feed: Codable, Equatable {
    let items: [OptionalValue<Item>]
}

@Test func optionalValueKeepsEveryElementWhenNoneFail() throws {
    let json = #"{"items":[{"id":1,"name":"a"},{"id":2,"name":"b"}]}"#

    let feed = try JSONDecoder().decode(Feed.self, from: Data(json.utf8))

    #expect(feed.items.compactMap(\.value) == [Item(id: 1, name: "a"), Item(id: 2, name: "b")])
}

/// The whole point: a malformed element must not take the array with it.
@Test func optionalValueSurvivesAMalformedElement() throws {
    let json = #"{"items":[{"id":1,"name":"a"},{"id":"two"},{"id":3,"name":"c"}]}"#

    let feed = try JSONDecoder().decode(Feed.self, from: Data(json.utf8))

    #expect(feed.items.count == 3)
    #expect(feed.items.compactMap(\.value) == [Item(id: 1, name: "a"), Item(id: 3, name: "c")])
}

/// A failed element holds its place, so an index into the decoded array still
/// refers to the same entry it did in the payload.
@Test func optionalValueLeavesAFailedElementInPosition() throws {
    let json = #"{"items":[{"nope":true},{"id":2,"name":"b"}]}"#

    let feed = try JSONDecoder().decode(Feed.self, from: Data(json.utf8))

    #expect(feed.items[0].value == nil)
    #expect(feed.items[1].value == Item(id: 2, name: "b"))
}

@Test func optionalValueEncodesAsTheValueItHolds() throws {
    let feed = Feed(items: [OptionalValue(Item(id: 1, name: "a"))])

    let data = try JSONEncoder().encode(feed)

    #expect(try JSONDecoder().decode(Feed.self, from: data) == feed)
    #expect(String(decoding: data, as: UTF8.self).contains(#""id":1"#))
}

@Test func optionalValueEncodesNothingHeldAsNull() throws {
    let data = try JSONEncoder().encode(Feed(items: [OptionalValue<Item>(nil)]))

    #expect(String(decoding: data, as: UTF8.self) == #"{"items":[null]}"#)
}
