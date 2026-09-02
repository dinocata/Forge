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

/// A sequence that can be rebuilt from its own elements.
///
/// Neither `Sequence` nor `Collection` requires an initialiser, so neither can be constructed
/// generically. `RangeReplaceableCollection` and `SetAlgebra` each require one, but no standard
/// protocol requires it of both `Array` and `Set` — which is why the lenient decoding below would
/// otherwise need an overload per concrete type.
public protocol SequenceInitializable: Sequence {
    init<Source: Sequence>(_ elements: Source) where Source.Element == Element
}

extension Array: SequenceInitializable {}
extension Set: SequenceInitializable {}

/// Collections keep the elements they can read rather than failing on the first one they cannot.
///
/// Stored data is often written by a different build of the app, and a collection holding one value
/// this version does not recognise — an enum case added since, or one since retired — would
/// otherwise fail to decode entirely and take every value beside it with it. Losing all of
/// someone's selection because of one unreadable entry is worse than losing that entry.
///
/// Element-wise leniency comes from ``OptionalValue``, whose decode yields `nil` rather than
/// throwing — which is also what keeps the unkeyed container advancing, since an element that threw
/// would leave the index where it was.
///
/// Leniency is for the *members*, not the shape: an object where a collection belongs is a
/// different kind of wrong, still throws, and reaches the fallback only as a missing value.
public extension KeyedDecodingContainer {

    func decode<C: SequenceInitializable & CodableDefaultValue>(
        _ type: CodableDefault<C>.Type,
        forKey key: Key
    ) throws -> CodableDefault<C> where C.Element: Decodable {
        try lenientlyDecoded(type, forKey: key, as: C.self)
    }

    /// The optional case is a separate overload rather than the same one, because `C` and `C?` are
    /// different types — and because they must fall back differently. A collection whose every
    /// element was unreadable decodes *empty*, since the value was stored and the user did answer;
    /// only a value that was never stored at all is `nil`.
    func decode<C: SequenceInitializable>(
        _ type: CodableDefault<C?>.Type,
        forKey key: Key
    ) throws -> CodableDefault<C?> where C.Element: Decodable {
        try lenientlyDecoded(type, forKey: key, as: C.self)
    }

    private func lenientlyDecoded<Value: CodableDefaultValue, C: SequenceInitializable>(
        _ type: CodableDefault<Value>.Type,
        forKey key: Key,
        as collection: C.Type = C.self
    ) throws -> CodableDefault<Value> where C.Element: Decodable {
        guard let elements = try decodeIfPresent([OptionalValue<C.Element>].self, forKey: key),
              let value = C(elements.compactMap(\.value)) as? Value else {
            return CodableDefault()
        }

        return CodableDefault(wrappedValue: value)
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
