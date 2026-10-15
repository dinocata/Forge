// Created by Dino Catalinac on 15.10.2026.

import Foundation

/// A release version such as `1.0` or `1.2.3`, as written in `CFBundleShortVersionString`, ordered
/// by its numeric components.
///
/// A missing minor or patch number counts as 0, so `1.2` equals `1.2.0`. Anything other than one to
/// three dot-separated non-negative integers — Apple's own limit for the key — fails to parse, so a
/// malformed value can be told apart from a low one.
public struct AppVersion: Comparable, Hashable, Sendable, CustomStringConvertible, Codable {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init(major: Int, minor: Int = 0, patch: Int = 0) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    public init?(_ string: String) {
        let parts = string.split(separator: ".", omittingEmptySubsequences: false)
        guard (1...3).contains(parts.count) else { return nil }
        var numbers: [Int] = []
        for part in parts {
            guard !part.isEmpty, part.allSatisfy({ ("0"..."9").contains($0) }), let value = Int(part) else { return nil }
            numbers.append(value)
        }
        self.init(major: numbers[0], minor: numbers.count > 1 ? numbers[1] : 0, patch: numbers.count > 2 ? numbers[2] : 0)
    }

    /// Decodes from the string form, such as `"1.2.3"`, and throws on a malformed one.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let version = AppVersion(string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Malformed version \"\(string)\"")
        }
        self = version
    }

    /// Encodes as the string form, which decoding reads back.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    public var description: String {
        "\(major).\(minor).\(patch)"
    }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}
