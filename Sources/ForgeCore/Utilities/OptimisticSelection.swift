//
//  OptimisticSelection.swift
//  ForgeCore
//
//  Created by Dino Catalinac on 28.09.2026.
//

import Foundation
import Observation

/// Keeps a selection responsive while applying its insertions and removals serially.
@MainActor
@Observable
public final class OptimisticSelection<Element: Hashable & Sendable> {
    public private(set) var values: Set<Element>

    @ObservationIgnored
    private var synchronizedValues: Set<Element>

    @ObservationIgnored
    private var latestChangeID: UUID?

    @ObservationIgnored
    private var authoritativeStateID = UUID()

    @ObservationIgnored
    private let operationQueue = TaskQueue<Void>()

    public init(_ values: Set<Element> = []) {
        self.values = values
        synchronizedValues = values
    }

    /// Selects an element immediately, then rolls it back if its operation fails.
    public func insert(
        _ element: Element,
        operation: @MainActor @Sendable @escaping (Element) async throws -> Void
    ) async throws {
        guard values.insert(element).inserted else {
            return
        }

        try await applyChange(to: element, isSelected: true, operation: operation)
    }

    /// Deselects an element immediately, then restores it if its operation fails.
    public func remove(
        _ element: Element,
        operation: @MainActor @Sendable @escaping (Element) async throws -> Void
    ) async throws {
        guard values.remove(element) != nil else {
            return
        }

        try await applyChange(to: element, isSelected: false, operation: operation)
    }

    /// Toggles an element immediately and performs the matching operation in FIFO order.
    public func toggle(
        _ element: Element,
        insert: @MainActor @Sendable @escaping (Element) async throws -> Void,
        remove: @MainActor @Sendable @escaping (Element) async throws -> Void
    ) async throws {
        if values.contains(element) {
            try await self.remove(element, operation: remove)
        } else {
            try await self.insert(element, operation: insert)
        }
    }

    /// Replaces the selection with authoritative state and cancels changes it supersedes.
    public func replace(with values: Set<Element>) async {
        let changeID = UUID()
        latestChangeID = changeID
        authoritativeStateID = UUID()
        self.values = values
        synchronizedValues = values

        await operationQueue.cancelAll()

        do {
            try await operationQueue.waitForAll()
        } catch {
            // Replacement deliberately supersedes the cancelled operations and their failures.
        }

        guard latestChangeID == changeID else {
            return
        }

        self.values = synchronizedValues
    }

    private func applyChange(
        to element: Element,
        isSelected: Bool,
        operation: @MainActor @Sendable @escaping (Element) async throws -> Void
    ) async throws {
        let changeID = UUID()
        let operationAuthoritativeStateID = authoritativeStateID
        latestChangeID = changeID

        do {
            try await operationQueue.enqueue { @MainActor [self] in
                guard synchronizedValues.contains(element) != isSelected else {
                    return
                }

                try await operation(element)
                try Task.checkCancellation()

                if isSelected {
                    synchronizedValues.insert(element)
                } else {
                    synchronizedValues.remove(element)
                }
            }
        } catch is CancellationError where authoritativeStateID != operationAuthoritativeStateID {
            // An authoritative replacement deliberately superseded this operation.
            return
        } catch {
            await synchronizeIfQueueIsEmpty(changeID: changeID)
            throw error
        }

        await synchronizeIfQueueIsEmpty(changeID: changeID)
    }

    private func synchronizeIfQueueIsEmpty(changeID: UUID) async {
        guard latestChangeID == changeID,
              await operationQueue.hasActiveTasks == false else {
            return
        }

        values = synchronizedValues
    }
}
