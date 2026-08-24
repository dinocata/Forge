// Created by Dino Catalinac on 25.08.2026.

import Testing
@testable import ForgeCore

/// Pins the conveniences to the sink. A logger whose conveniences called themselves compiled and
/// then hung on first use, so what matters is that each reaches the requirement exactly once.
@Suite
struct ForgeLoggerTests {

    @Test
    func logForwardsToTheSinkOnceWithTheDefaultLevel() {
        let logger = RecordingLogger()
        logger.log(message: "started")

        #expect(logger.messages.count == 1)
        #expect(logger.messages.first?.message == "started")
        #expect(logger.messages.first?.level == .debug)
    }

    @Test
    func logForwardsTheLevelItWasGiven() {
        let logger = RecordingLogger()
        logger.log(message: "slow", level: .warning)

        #expect(logger.messages.map(\.level) == [.warning])
    }

    @Test
    func captureForwardsToTheSinkOnceWithNoMessage() {
        let logger = RecordingLogger()
        logger.capture(error: RecordingLogger.Failure.example)

        #expect(logger.errors.count == 1)
        #expect(logger.errors.first?.message == nil)
    }

    @Test
    func captureForwardsTheMessageItWasGiven() {
        let logger = RecordingLogger()
        logger.capture(error: RecordingLogger.Failure.example, message: "while saving")

        #expect(logger.errors.map(\.message) == ["while saving"])
    }
}

private final class RecordingLogger: ForgeLogger, @unchecked Sendable {
    enum Failure: Error { case example }

    private(set) var messages: [(message: String, level: LogLevel)] = []
    private(set) var errors: [(error: Error, message: String?)] = []

    func log(_ message: String, level: LogLevel, file: StaticString, function: StaticString, line: UInt) {
        messages.append((message, level))
    }

    func capture(_ error: Error, message: String?, file: StaticString, function: StaticString, line: UInt) {
        errors.append((error, message))
    }
}
