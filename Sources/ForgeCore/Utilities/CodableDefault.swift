// Created by Dino Catalinac on 25.08.2026.

/// A Codable value with a canonical fallback for a missing keyed value.
public protocol CodableDefaultValue: Codable {
    static var defaultCodableValue: Self { get }
}

/// Preserves synthesized `Codable` conformance while providing a fallback for a missing key.
@propertyWrapper
public struct CodableDefault<Value: CodableDefaultValue>: Codable {
    public var wrappedValue: Value

    public init() {
        wrappedValue = Value.defaultCodableValue
    }

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try container.decode(Value.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

extension CodableDefault: Equatable where Value: Equatable {}
extension CodableDefault: Hashable where Value: Hashable {}
extension CodableDefault: Sendable where Value: Sendable {}

extension KeyedDecodingContainer {
    public func decode<Value: CodableDefaultValue>(
        _ type: CodableDefault<Value>.Type,
        forKey key: Key
    ) throws -> CodableDefault<Value> {
        try decodeIfPresent(type, forKey: key) ?? CodableDefault()
    }
}

extension Bool: CodableDefaultValue {
    public static let defaultCodableValue = false
}

extension Int: CodableDefaultValue {
    public static let defaultCodableValue = 0
}

extension Double: CodableDefaultValue {
    public static let defaultCodableValue = 0.0
}

extension Float: CodableDefaultValue {
    public static let defaultCodableValue: Float = 0.0
}

extension String: CodableDefaultValue {
    public static let defaultCodableValue = ""
}

extension Array: CodableDefaultValue where Element: Codable {
    public static var defaultCodableValue: [Element] { [] }
}

extension Set: CodableDefaultValue where Element: Codable {
    public static var defaultCodableValue: Set<Element> { [] }
}

extension Dictionary: CodableDefaultValue where Key: Codable, Value: Codable {
    public static var defaultCodableValue: [Key: Value] { [:] }
}
