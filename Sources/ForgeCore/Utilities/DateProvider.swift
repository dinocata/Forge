import Foundation

/// Provides the current date in production or a fixed date in deterministic contexts.
public struct DateProvider: Sendable {
    private let date: Date?

    public init(date: Date? = nil) {
        self.date = date
    }

    public var now: Date {
        date ?? .now
    }
}
