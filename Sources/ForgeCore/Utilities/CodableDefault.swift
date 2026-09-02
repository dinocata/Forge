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

/// Where the value is optional, an *undecodable* value falls back too, not only a missing key.
///
/// Chosen by overload resolution over the unconstrained `decode` above, which is the stricter of
/// the two: a value that cannot be decoded into a non-optional has no honest fallback, whereas
/// `nil` is exactly what an optional means. Lets one unreadable entry — a raw value written by a
/// newer build, or a case since retired — cost that entry rather than the whole container.
extension KeyedDecodingContainer {
    public func decode<Value: CodableDefaultValue & AnyOptional>(
        _ type: CodableDefault<Value>.Type,
        forKey key: Key
    ) throws -> CodableDefault<Value> {
        do {
            return try decodeIfPresent(type, forKey: key) ?? CodableDefault()
        } catch {
            return CodableDefault()
        }
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

extension Optional: CodableDefaultValue where Wrapped: Codable {
    public static var defaultCodableValue: Wrapped? { nil }
}
