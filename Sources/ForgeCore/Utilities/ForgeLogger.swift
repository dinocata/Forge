// Created by Dino Catalinac on 23.07.2026.

import Foundation

public protocol ForgeLogger: Sendable {
    func log(
        message: String,
        level: LogLevel,
        file: StaticString,
        function: StaticString,
        line: UInt
    )

    func capture(
        error: Error,
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
        log(message: message, level: level, file: file, function: function, line: line)
    }

    func capture(
        error: Error,
        message: String? = nil,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        capture(error: error, message: message, file: file, function: function, line: line)
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
