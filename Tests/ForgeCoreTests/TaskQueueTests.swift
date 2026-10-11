// Created by Dino Catalinac on 28.09.2026.

import ForgeCore
import Testing

@MainActor
struct TaskQueueTests {

    private enum TestError: Error {
        case expected
    }

    @Test(.timeLimit(.minutes(1)))
    func operationsRunInFIFOOrderAndReturnTheirOwnValues() async throws {
        let queue = TaskQueue<Int>()
        let firstStarted = Signal()
        let releaseFirst = Signal()
        let order = Recorder<Int>()

        let first = Task {
            try await queue.enqueue {
                await order.append(1)
                await firstStarted.send()
                await releaseFirst.wait()
                return 1
            }.value
        }

        await firstStarted.wait()

        let second = Task {
            try await queue.enqueue {
                await order.append(2)
                return 2
            }.value
        }

        await releaseFirst.send()

        #expect(try await first.value == 1)
        #expect(try await second.value == 2)
        #expect(await order.values == [1, 2])
        #expect(queue.hasActiveTasks == false)
    }

    @Test(.timeLimit(.minutes(1)))
    func failureDoesNotCancelTheNextOperation() async throws {
        let queue = TaskQueue<Int>()
        let firstStarted = Signal()
        let releaseFirst = Signal()

        let failing = Task {
            try await queue.enqueue {
                await firstStarted.send()
                await releaseFirst.wait()
                throw TestError.expected
            }.value
        }

        await firstStarted.wait()
        let succeeding = Task { try await queue.enqueue { 2 }.value }
        await releaseFirst.send()

        do {
            _ = try await failing.value
            Issue.record("Expected the first operation to fail.")
        } catch TestError.expected {
            // Expected.
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(try await succeeding.value == 2)
    }

    @Test(.timeLimit(.minutes(1)))
    func cancellingOneCallerDoesNotCancelTheNextOperation() async throws {
        let queue = TaskQueue<Int>()
        let firstStarted = Signal()

        let cancelled = Task {
            try await queue.enqueue {
                await firstStarted.send()
                try await Task.sleep(for: .seconds(60))
                return 1
            }.value
        }

        await firstStarted.wait()
        let succeeding = Task { try await queue.enqueue { 2 }.value }
        cancelled.cancel()

        await expectCancellation(from: cancelled)
        #expect(try await succeeding.value == 2)
    }

    @Test(.timeLimit(.minutes(1)))
    func cancelAllCancelsTheActiveAndPendingOperations() async {
        let queue = TaskQueue<Int>()
        let firstStarted = Signal()

        let active = Task {
            try await queue.enqueue {
                await firstStarted.send()
                try await Task.sleep(for: .seconds(60))
                return 1
            }.value
        }

        await firstStarted.wait()
        let pending = Task { try await queue.enqueue { 2 }.value }

        // Give the pending caller a turn to enter the queue behind the parked operation.
        await Task.yield()
        queue.cancelAll()

        await expectCancellation(from: active)
        await expectCancellation(from: pending)
        #expect(queue.hasActiveTasks == false)
    }

    @Test(.timeLimit(.minutes(1)))
    func waitForAllIncludesOperationsAddedWhileTheQueueIsDraining() async throws {
        let queue = TaskQueue<Int>()
        let firstStarted = Signal()
        let releaseFirst = Signal()

        let first = Task {
            try await queue.enqueue {
                await firstStarted.send()
                await releaseFirst.wait()
                return 1
            }.value
        }

        await firstStarted.wait()
        let waiting = Task { try await queue.waitForAll() }
        await Task.yield()

        let second = Task { try await queue.enqueue { 2 }.value }
        await Task.yield()
        await releaseFirst.send()

        #expect(try await waiting.value == [1, 2])
        #expect(try await first.value == 1)
        #expect(try await second.value == 2)
    }

    @Test(.timeLimit(.minutes(1)))
    func waitForAllThrowsOnlyAfterLaterOperationsFinish() async throws {
        let queue = TaskQueue<Int>()
        let firstStarted = Signal()
        let releaseFirst = Signal()
        let laterFinished = Signal()

        let failing = Task {
            try await queue.enqueue {
                await firstStarted.send()
                await releaseFirst.wait()
                throw TestError.expected
            }.value
        }

        await firstStarted.wait()
        let succeeding = Task {
            try await queue.enqueue {
                await laterFinished.send()
                return 2
            }.value
        }
        let waiting = Task { try await queue.waitForAll() }
        await releaseFirst.send()

        do {
            _ = try await waiting.value
            Issue.record("Expected the drain to report its first failure.")
        } catch TestError.expected {
            #expect(await laterFinished.hasBeenSent)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        _ = await failing.result
        #expect(try await succeeding.value == 2)
    }

    @Test
    func operationCanChooseMainActorIsolation() async throws {
        let queue = TaskQueue<Int>()

        let value = try await queue.enqueue { @MainActor in
            MainActor.preconditionIsolated()
            return 1
        }.value

        #expect(value == 1)
    }

    @Test
    func waitForAllReturnsImmediatelyWhenTheQueueIsEmpty() async throws {
        let queue = TaskQueue<Int>()

        #expect(try await queue.waitForAll() == [])
    }

    @Test(.timeLimit(.minutes(1)))
    func simultaneousWaitersReceiveTheSameDrainResults() async throws {
        let queue = TaskQueue<Int>()
        let started = Signal()
        let release = Signal()

        let operation = Task {
            try await queue.enqueue {
                await started.send()
                await release.wait()
                return 1
            }.value
        }

        await started.wait()
        let firstWaiter = Task { try await queue.waitForAll() }
        let secondWaiter = Task { try await queue.waitForAll() }
        await Task.yield()
        await release.send()

        #expect(try await firstWaiter.value == [1])
        #expect(try await secondWaiter.value == [1])
        #expect(try await operation.value == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func cancellingAWaiterDoesNotCancelQueueOperations() async throws {
        let queue = TaskQueue<Int>()
        let started = Signal()
        let release = Signal()

        let operation = Task {
            try await queue.enqueue {
                await started.send()
                await release.wait()
                return 1
            }.value
        }

        await started.wait()
        let waiter = Task { try await queue.waitForAll() }
        await Task.yield()
        waiter.cancel()
        await expectCancellation(from: waiter)

        await release.send()
        #expect(try await operation.value == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func consecutiveDrainsDoNotShareResults() async throws {
        let queue = TaskQueue<Int>()
        let firstStarted = Signal()
        let releaseFirst = Signal()

        let first = Task {
            try await queue.enqueue {
                await firstStarted.send()
                await releaseFirst.wait()
                return 1
            }.value
        }

        await firstStarted.wait()
        let firstDrain = Task { try await queue.waitForAll() }
        await Task.yield()
        await releaseFirst.send()
        #expect(try await firstDrain.value == [1])
        #expect(try await first.value == 1)

        let secondStarted = Signal()
        let releaseSecond = Signal()
        let second = Task {
            try await queue.enqueue {
                await secondStarted.send()
                await releaseSecond.wait()
                return 2
            }.value
        }

        await secondStarted.wait()
        let secondDrain = Task { try await queue.waitForAll() }
        await Task.yield()
        await releaseSecond.send()
        #expect(try await secondDrain.value == [2])
        #expect(try await second.value == 2)
    }

    @Test(.timeLimit(.minutes(1)))
    func cancelAllMakesAnActiveWaiterThrowCancellation() async {
        let queue = TaskQueue<Int>()
        let started = Signal()

        let operation = Task {
            try await queue.enqueue {
                await started.send()
                try await Task.sleep(for: .seconds(60))
                return 1
            }.value
        }

        await started.wait()
        let waiter = Task { try await queue.waitForAll() }
        await Task.yield()
        queue.cancelAll()

        await expectCancellation(from: waiter)
        await expectCancellation(from: operation)
    }

    @Test(.timeLimit(.minutes(1)))
    func operationsEnqueuedFromSynchronousCodeRunInCallOrder() async throws {
        let queue = TaskQueue<Int>()
        let order = Recorder<Int>()
        let count = 50

        for index in 0..<count {
            queue.enqueue {
                await order.append(index)
                return index
            }
        }

        #expect(try await queue.waitForAll() == Array(0..<count))
        #expect(await order.values == Array(0..<count))
    }

    @Test(.timeLimit(.minutes(1)))
    func cancellingAWaitingOperationFinishesItWithoutWaitingForTheActiveOne() async throws {
        let queue = TaskQueue<Int>()
        let firstStarted = Signal()
        let releaseFirst = Signal()

        let first = queue.enqueue {
            await firstStarted.send()
            await releaseFirst.wait()
            return 1
        }
        await firstStarted.wait()

        let waiting = queue.enqueue { 2 }
        waiting.cancel()

        do {
            _ = try await waiting.value
            Issue.record("Expected cancellation.")
        } catch is CancellationError {
            // Expected, while the first operation is still running.
        }

        await releaseFirst.send()
        #expect(try await first.value == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func aCancelledWaitingOperationDoesNotLetTheNextOneOvertakeTheActiveOne() async throws {
        let queue = TaskQueue<Int>()
        let firstStarted = Signal()
        let releaseFirst = Signal()
        let order = Recorder<Int>()

        let first = queue.enqueue {
            await firstStarted.send()
            await releaseFirst.wait()
            await order.append(1)
            return 1
        }
        await firstStarted.wait()

        queue.enqueue { 2 }.cancel()
        let third = queue.enqueue {
            await order.append(3)
            return 3
        }

        await releaseFirst.send()
        #expect(try await first.value == 1)
        #expect(try await third.value == 3)
        #expect(await order.values == [1, 3])
    }
}

struct SharedTaskQueueTests {

    @Test(.timeLimit(.minutes(1)))
    func callersOnDifferentActorsShareOneQueue() async throws {
        let queue = SharedTaskQueue<Int>()
        let order = Recorder<Int>()

        let mainActorValue = try await Task { @MainActor in
            try await queue.enqueue {
                await order.append(1)
                return 1
            }
        }
        .value
        let otherActorValue = try await Recorder<Int>().enqueue(on: queue) {
            await order.append(2)
            return 2
        }

        #expect(mainActorValue == 1)
        #expect(otherActorValue == 2)
        #expect(await order.values == [1, 2])
        #expect(try await queue.waitForAll() == [])
        #expect(await queue.hasActiveTasks == false)
    }

    @Test(.timeLimit(.minutes(1)))
    func cancellingACallerCancelsItsOperation() async throws {
        let queue = SharedTaskQueue<Int>()
        let started = Signal()

        let cancelled = Task {
            try await queue.enqueue {
                await started.send()
                try await Task.sleep(for: .seconds(60))
                return 1
            }
        }

        await started.wait()
        cancelled.cancel()

        await expectCancellation(from: cancelled)
        #expect(try await queue.enqueue { 2 } == 2)
    }
}

private actor Signal {
    private var isSent = false
    private var continuations: [CheckedContinuation<Void, Never>] = []

    var hasBeenSent: Bool { isSent }

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

private actor Recorder<Value: Sendable> {
    private(set) var values: [Value] = []

    func append(_ value: Value) {
        values.append(value)
    }

    /// Enqueues from this actor, as a caller on another actor than the test would.
    func enqueue(
        on queue: SharedTaskQueue<Int>,
        _ operation: @escaping @Sendable () async throws -> Int
    ) async throws -> Int {
        try await queue.enqueue(operation)
    }
}

private func expectCancellation<Value>(from task: Task<Value, Error>) async {
    do {
        _ = try await task.value
        Issue.record("Expected cancellation.")
    } catch is CancellationError {
        // Expected.
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}
