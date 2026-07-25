//
//  TaskQueue.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//

import Foundation
import OrderedCollections

public actor TaskQueue<T: Sendable> {
    public var hasActiveTasks: Bool { !tasks.isEmpty }

    private var tasks: IdentifiedArrayOf<TaskEntry<T>> = []
    private var activeTaskID: UUID?

    public init() {}

    public func enqueue(
        _ task: @Sendable @escaping (T?) async throws -> T,
        onComplete: (@Sendable (Result<T, Error>) async -> Void)? = nil
    ) {
        let lastRunningTask = tasks.last?.task
        let taskID = UUID()
        let queueWasEmpty = tasks.isEmpty

        let newTask = Task { [self] in
            do {
                let lastValue = try await lastRunningTask?.value
                try Task.checkCancellation()

                if let lastRunningTask,
                   let lastRunningTaskID = entryID(for: lastRunningTask) {
                    tasks.remove(id: lastRunningTaskID)
                }

                activeTaskID = taskID
                let value = try await task(lastValue)
                try Task.checkCancellation()

                if activeTaskID == taskID {
                    activeTaskID = nil
                }

                if tasks.count == 1 {
                    tasks.removeAll()
                }

                if tasks.isEmpty {
                    await onComplete?(.success(value))
                }

                return value
            } catch {
                if activeTaskID == taskID {
                    activeTaskID = nil
                }

                if hasActiveTasks {
                    let tasksToCancel = tasks
                    tasks.removeAll()
                    tasksToCancel.forEach { $0.task.cancel() }
                    await onComplete?(.failure(error))
                }

                throw error
            }
        }

        if queueWasEmpty {
            activeTaskID = taskID
        }
        tasks.append(TaskEntry(id: taskID, task: newTask))
    }

    public func cancel() {
        let currentTask = if let activeTaskID {
            tasks[id: activeTaskID]?.task
        } else {
            tasks.first?.task
        }

        guard let currentTask else {
            return
        }

        currentTask.cancel()
    }

    @discardableResult
    public func waitForCompletion() async throws -> T? {
        try await tasks.last?.task.value
    }
}

private extension TaskQueue {
    func entryID(for task: Task<T, Error>) -> UUID? {
        tasks.first(where: { $0.task == task })?.id
    }
}

private struct TaskEntry<T: Sendable>: Identifiable {
    let id: UUID
    let task: Task<T, Error>
}
