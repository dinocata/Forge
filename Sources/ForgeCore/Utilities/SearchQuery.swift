// Created by Dino Catalinac on 26.09.2026.

import Foundation

/// What a user typed into a search field, matched loosely against names: every word must appear,
/// in any order, ignoring case, accents, and anything that is not a letter or digit.
///
/// So "check in" finds "Check-in" and "york new" finds "New York". An empty query matches
/// everything. Build it once per search and reuse it across the items being filtered.
public struct SearchQuery: Sendable, Equatable {
    private let terms: [String]

    public init(_ text: String) {
        terms = text.split { !$0.isLetter && !$0.isNumber }.map { Self.key(for: String($0)) }
    }

    public var isEmpty: Bool {
        terms.isEmpty
    }

    public func matches(_ text: String) -> Bool {
        guard !terms.isEmpty else { return true }
        let key = Self.key(for: text)
        return terms.allSatisfy(key.contains)
    }

    /// Separators are dropped rather than split on, so a word typed with or without one still
    /// matches ("checkin" finds "Check-in").
    private static func key(for text: String) -> String {
        String(text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .filter { $0.isLetter || $0.isNumber })
    }
}
