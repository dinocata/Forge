// Created by Dino Catalinac on 23.07.2026.

import Foundation

/// A destination for diagnostics. Conformers implement the requirements below, which take every
/// value explicitly; callers use the conveniences in the extension, which fill in the level and
/// the call site.
///
/// The requirement takes its first argument unlabelled and the convenience labels it, so the two
/// cannot be mistaken for one another. They must differ somewhere: an extension member whose
/// signature matches a requirement *becomes* that requirement's default implementation, so a
/// convenience that only added default arguments would witness the requirement it meant to call
/// and recurse into itself forever. As written, a conformer that gets the shape wrong fails to
/// compile instead.
public protocol ForgeLogger: Sendable {
    func log(
        _ message: String,
        level: LogLevel,
        file: StaticString,
        function: StaticString,
        line: UInt
    )

    func capture(
        _ error: Error,
        message: String?,
        file: StaticString,
        function: StaticString,
        line: UInt
    )
}

public extension ForgeLogger {
    func log(
        message: String,
        level: LogLevel = .debug,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log(message, level: level, file: file, function: function, line: line)
    }

    func capture(
        error: Error,
        message: String? = nil,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        capture(error, message: message, file: file, function: function, line: line)
    }
}

public enum LogLevel: String, Codable, Sendable {
    case error = "Error"
    case warning = "Warning"
    case info = "Information"
    case debug = "Debug"

    public func shouldInclude(_ level: LogLevel) -> Bool {
        switch self {
        case .debug:
            return true // Debug includes all levels
        case .info:
            return level != .debug // Info includes info, warning, and error
        case .warning:
            return level == .warning || level == .error // Warning includes warning and error
        case .error:
            return level == .error // Error only includes error
        }
    }
}
