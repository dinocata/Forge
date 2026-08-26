// swiftlint:disable:this file_name superfluous_disable_command
// Created by Dino Catalinac on 27.08.2026.

import Foundation

public enum CodableDictionaryError: Error, Equatable, Sendable {
    case encodedValueIsNotDictionary
    case invalidJSONObject
}

public extension Encodable {
    /// Encodes this value as a JSON-compatible dictionary.
    func encodedDictionary(using encoder: JSONEncoder = JSONEncoder()) throws -> [String: Any] {
        let data = try encoder.encode(self)
        let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        guard let dictionary = object as? [String: Any] else {
            throw CodableDictionaryError.encodedValueIsNotDictionary
        }

        return dictionary
    }
}

public extension Dictionary where Key == String, Value == Any {
    /// Decodes a JSON-compatible dictionary into a Codable value.
    func decode<Decoded: Decodable>(
        _ type: Decoded.Type = Decoded.self,
        using decoder: JSONDecoder = JSONDecoder()
    ) throws -> Decoded {
        guard JSONSerialization.isValidJSONObject(self) else {
            throw CodableDictionaryError.invalidJSONObject
        }

        let data = try JSONSerialization.data(withJSONObject: self)
        return try decoder.decode(type, from: data)
    }
}
