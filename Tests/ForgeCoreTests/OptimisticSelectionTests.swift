// Created by Dino Catalinac on 28.09.2026.

import ForgeCore
import Testing

@MainActor
struct OptimisticSelectionTests {

    private enum TestError: Error {
        case expected
    }

    @Test(.timeLimit(.minutes(1)))
    func insertionIsVisibleBeforeItsOperationFinishes() async throws {
        let selection = OptimisticSelection<Int>()
        let started = SelectionSignal()
        let release = SelectionSignal()

        let insertion = Task { @MainActor in
            try await selection.insert(1) { _ in
                await started.send()
                await release.wait()
            }
        }

        await started.wait()
        #expect(selection.values == [1])

        await release.send()
        try await insertion.value
        #expect(selection.values == [1])
    }

    @Test(.timeLimit(.minutes(1)))
    func failedInsertionRollsBackAfterTheQueueEmpties() async {
        let selection = OptimisticSelection<Int>()

        do {
            try await selection.insert(1) { _ in throw TestError.expected }
            Issue.record("Expected insertion to fail.")
        } catch TestError.expected {
            #expect(selection.values.isEmpty)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func failedRemovalRestoresTheCommittedSelection() async {
        let selection = OptimisticSelection([1])

        do {
            try await selection.remove(1) { _ in throw TestError.expected }
            Issue.record("Expected removal to fail.")
        } catch TestError.expected {
            #expect(selection.values == [1])
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func insertAndRemoveAreIdempotent() async throws {
        let selection = OptimisticSelection([1])
        let operations = SelectionRecorder<String>()

        try await selection.insert(1) { _ in await operations.append("insert") }
        try await selection.remove(2) { _ in await operations.append("remove") }

        #expect(await operations.values.isEmpty)
        #expect(selection.values == [1])
    }

    @Test
    func togglePerformsTheOperationMatchingTheOptimisticState() async throws {
        let selection = OptimisticSelection<Int>()
        let operations = SelectionRecorder<String>()

        try await selection.toggle(
            1,
            insert: { _ in await operations.append("insert") },
            remove: { _ in await operations.append("remove") }
        )
        try await selection.toggle(
            1,
            insert: { _ in await operations.append("insert") },
            remove: { _ in await operations.append("remove") }
        )

        #expect(await operations.values == ["insert", "remove"])
        #expect(selection.values.isEmpty)
    }

    @Test(.timeLimit(.minutes(1)))
    func rapidChangesRunSeriallyAndKeepTheirOptimisticState() async throws {
        let selection = OptimisticSelection<Int>()
        let firstStarted = SelectionSignal()
        let releaseFirst = SelectionSignal()
        let operations = SelectionRecorder<String>()

        let insertion = Task { @MainActor in
            try await selection.insert(1) { _ in
                await operations.append("insert")
                await firstStarted.send()
                await releaseFirst.wait()
            }
        }

        await firstStarted.wait()
        let removal = Task { @MainActor in
            try await selection.remove(1) { _ in
                await operations.append("remove")
            }
        }

        await Task.yield()
        #expect(selection.values.isEmpty)

        await releaseFirst.send()
        try await insertion.value
        try await removal.value

        #expect(await operations.values == ["insert", "remove"])
        #expect(selection.values.isEmpty)
    }

    @Test(.timeLimit(.minutes(1)))
    func failedChangeDoesNotOverwriteANewerOptimisticChange() async throws {
        let selection = OptimisticSelection<Int>()
        let firstStarted = SelectionSignal()
        let releaseFirst = SelectionSignal()

        let failing = Task { @MainActor in
            try await selection.insert(1) { _ in
                await firstStarted.send()
                await releaseFirst.wait()
                throw TestError.expected
            }
        }

        await firstStarted.wait()
        let succeeding = Task { @MainActor in
            try await selection.insert(2) { _ in }
        }

        await Task.yield()
        #expect(selection.values == [1, 2])
        await releaseFirst.send()

        _ = await failing.result
        try await succeeding.value
        #expect(selection.values == [2])
    }

    @Test(.timeLimit(.minutes(1)))
    func redundantChangeIsSkippedWhenAnEarlierOperationFails() async throws {
        let selection = OptimisticSelection<Int>()
        let firstStarted = SelectionSignal()
        let releaseFirst = SelectionSignal()
        let removals = SelectionRecorder<Int>()

        let insertion = Task { @MainActor in
            try await selection.insert(1) { _ in
                await firstStarted.send()
                await releaseFirst.wait()
                throw TestError.expected
            }
        }

        await firstStarted.wait()
        let removal = Task { @MainActor in
            try await selection.remove(1) { element in
                await removals.append(element)
            }
        }

        await releaseFirst.send()
        _ = await insertion.result
        try await removal.value

        #expect(await removals.values.isEmpty)
        #expect(selection.values.isEmpty)
    }

    @Test(.timeLimit(.minutes(1)))
    func replacementSilentlyCancelsPendingChangesAndAdoptsAuthoritativeValues() async throws {
        let selection = OptimisticSelection<Int>()
        let started = SelectionSignal()

        let insertion = Task { @MainActor in
            try await selection.insert(1) { _ in
                await started.send()
                try await Task.sleep(for: .seconds(60))
            }
        }

        await started.wait()
        await selection.replace(with: [2])

        #expect(selection.values == [2])
        try await insertion.value
    }

    @Test
    func operationCancellationStillReachesTheCaller() async {
        let selection = OptimisticSelection<Int>()

        do {
            try await selection.insert(1) { _ in throw CancellationError() }
            Issue.record("Expected operation cancellation to reach the caller.")
        } catch is CancellationError {
            // Expected.
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(selection.values.isEmpty)
    }
}

private actor SelectionSignal {
    private var isSent = false
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard isSent == false else {
            return
        }

        await withCheckedContinuation { continuations.append($0) }
    }

    func send() {
        isSent = true
        continuations.forEach { $0.resume() }
        continuations.removeAll()
    }
}

private actor SelectionRecorder<Value: Sendable> {
    private(set) var values: [Value] = []

    func append(_ value: Value) {
        values.append(value)
    }
}
