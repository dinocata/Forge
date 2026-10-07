// Created by Dino Catalinac on 07.10.2026.

import Foundation

/// A logger that forwards every call to each of its loggers in order, so an app can send the same
/// diagnostics to several destinations (a console and a crash reporter) behind one `ForgeLogger`.
public struct CompositeLogger: ForgeLogger {
    private let loggers: [any ForgeLogger]

    public init(_ loggers: [any ForgeLogger]) {
        self.loggers = loggers
    }

    public func log(_ message: String, level: LogLevel, file: StaticString, function: StaticString, line: UInt) {
        for logger in loggers {
            logger.log(message, level: level, file: file, function: function, line: line)
        }
    }

    public func capture(_ error: Error, message: String?, file: StaticString, function: StaticString, line: UInt) {
        for logger in loggers {
            logger.capture(error, message: message, file: file, function: function, line: line)
        }
    }
}
