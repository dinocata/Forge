//
//  RouterTests.swift
//  ForgeUI
//
//  Created by Dino Catalinac on 21.08.2026.
//

import ForgeUI
import Testing

@MainActor
struct RouterTests {
    @Test func pushingSeveralDestinationsUpdatesThePathOnce() {
        let router = Router(root: TestDestination.root)

        router.push(.first, .second)

        #expect(router.path == [.first, .second])
    }

    @Test func pushingTheCurrentDestinationAmongSeveralDoesNotDuplicateIt() {
        let router = Router(root: TestDestination.root, path: [.first])

        router.push(.first, .second, .second)

        #expect(router.path == [.first, .second])
    }
}

private enum TestDestination: Hashable, Identifiable, Sendable {
    case root
    case first
    case second

    var id: Self { self }
}
