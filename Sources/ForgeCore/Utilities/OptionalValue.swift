// Created by Dino Catalinac on 19.08.2026.

/// A wrapper around an optional value.
///
/// It exists because `Optional` cannot carry a different `Decodable` conformance
/// than the one the standard library gives it, and a distinct type can. Decoding
/// is all-or-nothing by default, so one malformed element aborts the array it
/// sits in and loses every valid element behind it. The conformance below decodes
/// into ``value`` and leaves it `nil` on failure rather than throwing, which keeps
/// the failure local to that element and preserves its position:
///
/// ```swift
/// struct Feed: Decodable {
///     let items: [OptionalValue<Item>]
/// }
///
/// let usable = feed.items.compactMap(\.value)
/// ```
///
/// The wrapper itself claims nothing beyond holding an optional — codability is
/// conditional and belongs to `Wrapped`.
public struct OptionalValue<Wrapped> {

    public let value: Wrapped?

    public init(_ value: Wrapped?) {
        self.value = value
    }
}

extension OptionalValue: Decodable where Wrapped: Decodable {

    public init(from decoder: any Decoder) throws {
        value = try? Wrapped(from: decoder)
    }
}

extension OptionalValue: Encodable where Wrapped: Encodable {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension OptionalValue: Equatable where Wrapped: Equatable {}
extension OptionalValue: Hashable where Wrapped: Hashable {}
extension OptionalValue: Sendable where Wrapped: Sendable {}
