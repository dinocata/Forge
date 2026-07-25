//
//  Sequence+Extensions.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//

import AsyncAlgorithms
import Foundation
import OrderedCollections

public extension Sequence {

    @discardableResult
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()
        for element in self {
            try await values.append(transform(element))
        }
        return values
    }

    func concurrentMap<T: Sendable>(
        _ transform: @Sendable @escaping (Element) async throws -> T
    ) async rethrows -> [T] where Element: Sendable {
        try await withThrowingTaskGroup(of: IndexedWrapper<T>.self, returning: [T].self) { taskGroup in
            enumerated().forEach { index, element in
                taskGroup.addTask {
                    let result: T = try await transform(element)
                    return IndexedWrapper(index: index, wrapped: result)
                }
            }

            return try await taskGroup
                .collect()
                .sorted(by: \.index)
                .map(\.wrapped)
        }
    }

    func concurrentForEach(
        _ body: @Sendable @escaping (Element) async throws -> Void
    ) async rethrows where Element: Sendable {
        _ = try await concurrentMap(body)
    }
}

public extension Sequence where Element: Hashable {

    var asSet: Set<Element> {
        Set(self)
    }

    var asOrderedSet: OrderedSet<Element> {
        OrderedSet(self)
    }

    func removeDuplicates() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}

public extension Sequence where Element: Identifiable {

    var asIdentifiedArray: IdentifiedArrayOf<Element> {
        IdentifiedArray(uniqueElements: self)
    }

    var asIdentifiedDictionary: [Element.ID: Element] {
        asIdentifiedDictionary(by: \.id)
    }
}

public extension Sequence {

    var asArray: [Element] {
        Array(self)
    }

    /// Builds a dictionary from the sequence using the given key path.
    /// Later occurrences of the same key silently overwrite earlier ones.
    func asIdentifiedDictionary<ID: Hashable>(by keyPath: KeyPath<Element, ID>) -> [ID: Element] {
        var dictionary: [ID: Element] = [:]
        for element in self {
            let key = element[keyPath: keyPath]
            dictionary[key] = element
        }
        return dictionary
    }

    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>, sortOrder: SortOrder = .forward) -> [Element] {
        sorted { lhs, rhs -> Bool in
            switch sortOrder {
            case .forward:
                lhs[keyPath: keyPath] < rhs[keyPath: keyPath]
            case .reverse:
                lhs[keyPath: keyPath] > rhs[keyPath: keyPath]
            }
        }
    }

    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T?>, sortOrder: SortOrder = .forward) -> [Element] {
        sorted { lhs, rhs -> Bool in
            guard let lhsValue = lhs[keyPath: keyPath], let rhsValue = rhs[keyPath: keyPath] else {
                return false
            }
            switch sortOrder {
            case .forward:
                return lhsValue < rhsValue
            case .reverse:
                return lhsValue > rhsValue
            }
        }
    }

    func max<T: Comparable>(by keyPath: KeyPath<Element, T>) -> Element? {
        self.max { lhs, rhs in
            lhs[keyPath: keyPath] < rhs[keyPath: keyPath]
        }
    }
}

private struct IndexedWrapper<Wrapped>: Sendable where Wrapped: Sendable {
    public let index: Int
    public let wrapped: Wrapped

    public init(index: Int, wrapped: Wrapped) {
        self.index = index
        self.wrapped = wrapped
    }
}
