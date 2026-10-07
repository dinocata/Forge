// Created by Dino Catalinac on 07.10.2026.

import Testing
@testable import ForgeCore

/// Pins the fan-out: each call reaches every child exactly once, in order, unchanged.
@Suite
struct CompositeLoggerTests {

    @Test
    func logReachesEveryLoggerOnceInOrder() {
        let journal = Journal()
        let logger = CompositeLogger([RecordingLogger(name: "first", journal: journal), RecordingLogger(name: "second", journal: journal)])
        logger.log(message: "started", level: .warning)

        #expect(journal.entries == ["first log started Warning", "second log started Warning"])
    }

    @Test
    func captureReachesEveryLoggerOnceInOrder() {
        let journal = Journal()
        let logger = CompositeLogger([RecordingLogger(name: "first", journal: journal), RecordingLogger(name: "second", journal: journal)])
        logger.capture(error: Journal.Failure.example, message: "while saving")

        #expect(journal.entries == ["first capture example while saving", "second capture example while saving"])
    }

    @Test
    func anEmptyCompositeDoesNothing() {
        let logger = CompositeLogger([])
        logger.log(message: "ignored")
        logger.capture(error: Journal.Failure.example)
    }
}

private final class Journal: @unchecked Sendable {
    enum Failure: Error { case example }

    var entries: [String] = []
}

private struct RecordingLogger: ForgeLogger {
    let name: String
    let journal: Journal

    func log(_ message: String, level: LogLevel, file: StaticString, function: StaticString, line: UInt) {
        journal.entries.append("\(name) log \(message) \(level.rawValue)")
    }

    func capture(_ error: Error, message: String?, file: StaticString, function: StaticString, line: UInt) {
        journal.entries.append("\(name) capture \(error) \(message ?? "nil")")
    }
}
