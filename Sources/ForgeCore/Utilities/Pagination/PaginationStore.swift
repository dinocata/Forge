//
//  PaginationStore.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//

import Foundation

/// Generic pagination store that manages cursor-based pagination for any
/// identifiable items. Provides smart loading thresholds that trigger when
/// users scroll near the end of the current items.
@MainActor
@Observable
public final class PaginationStore<Item: Identifiable & Equatable, Cursor: Sendable> {

    public typealias DataProvider = (Cursor?, _ pageSize: Int, _ refresh: Bool) async throws -> PaginationResponse<Item, Cursor>

    public var state: ResultState<IdentifiedArrayOf<Item>> {
        asyncState.state
    }

    public var isLoadingNextPage: Bool {
        asyncState.isLoading && asyncState.value.isSome
    }

    public var items: IdentifiedArrayOf<Item> {
        get {
            asyncState.value ?? []
        }
        set {
            asyncState.value = newValue
        }
    }

    public var dataProvider: DataProvider?

    public private(set) var pageSize: Int
    private var pageLoadThreshold: Int

    private var nextPageCursor: Cursor?
    public private(set) var hasNextPage: Bool = true

    private var asyncState: AsyncState<IdentifiedArrayOf<Item>> = .init()

    public init(pageSize: Int, pageLoadThreshold: Int? = nil) {
        self.pageSize = pageSize
        self.pageLoadThreshold = pageLoadThreshold ?? pageSize / 4
    }

    public func setPageSize(to pageSize: Int, pageLoadThreshold: Int? = nil) {
        self.pageSize = pageSize
        self.pageLoadThreshold = pageLoadThreshold ?? pageSize / 4
    }

    public func shouldLoadNextPage(for item: Item) -> Bool {
        guard let itemIndex = items.index(id: item.id) else {
            return false
        }
        let thresholdPosition = max(items.count, pageSize) - pageLoadThreshold - 1
        return itemIndex >= thresholdPosition
    }

    public func loadNextPage(refresh: Bool = false, from dataProvider: @escaping DataProvider) async {
        guard !state.isLoading else {
            return
        }

        self.dataProvider = dataProvider
        guard hasNextPage else {
            return
        }

        var currentItems: IdentifiedArrayOf<Item> = refresh ? [] : self.items

        await asyncState.perform(options: .init(skipLoadingWhenSuccessful: false)) {
            try Task.checkCancellation()
            let page = try await dataProvider(self.nextPageCursor, self.pageSize, refresh)
            try Task.checkCancellation()

            if let nextPageCursor = page.next {
                self.nextPageCursor = nextPageCursor
            } else {
                self.hasNextPage = false
            }

            currentItems.reserveCapacity(currentItems.count + page.items.count)
            page.items.forEach { item in
                currentItems.updateOrAppend(item)
            }
            return currentItems
        }
    }

    public func loadNextPage() async {
        guard let dataProvider else {
            assertionFailure("Data provider not set")
            return
        }
        await loadNextPage(from: dataProvider)
    }

    @discardableResult
    public func loadNextPage(for item: Item) -> Task<Void, Never>? {
        guard let dataProvider else {
            assertionFailure("Data provider not set")
            return nil
        }
        guard shouldLoadNextPage(for: item) else {
            return nil
        }
        return Task {
            await loadNextPage(from: dataProvider)
        }
    }

    public func refresh() async {
        guard let dataProvider else {
            assertionFailure("Data provider not set")
            return
        }
        guard !state.isLoading else {
            return
        }

        nextPageCursor = nil
        hasNextPage = true
        await loadNextPage(refresh: true, from: dataProvider)
    }

    public func reset() {
        nextPageCursor = nil
        hasNextPage = true
        asyncState.reset()
    }
}
