// Created by Dino Catalinac on 27.08.2026.

import Foundation
import Testing
@testable import ForgeCore

struct CodableDictionaryTests {
    @Test func valueRoundTripsThroughDictionary() throws {
        let value = Fixture(name: "Example", count: 3)

        let dictionary = try value.encodedDictionary()
        let decoded = try dictionary.decode(Fixture.self)

        #expect(decoded == value)
    }

    @Test func scalarCannotEncodeAsDictionary() throws {
        #expect(throws: CodableDictionaryError.encodedValueIsNotDictionary) {
            try "Example".encodedDictionary()
        }
    }

    @Test func nonJSONDictionaryCannotDecode() throws {
        let dictionary: [String: Any] = ["date": Date()]

        #expect(throws: CodableDictionaryError.invalidJSONObject) {
            try dictionary.decode(Fixture.self)
        }
    }
}

private struct Fixture: Codable, Equatable {
    let name: String
    let count: Int
}
