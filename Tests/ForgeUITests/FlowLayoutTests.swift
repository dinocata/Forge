// Created by Dino Catalinac on 03.09.2026.

import Foundation
import Testing
@testable import ForgeUI

/// Two short items either side of a tall one, which is the only shape where item alignment shows.
private let sizes = [
    CGSize(width: 40, height: 20),
    CGSize(width: 40, height: 60),
    CGSize(width: 40, height: 40)
]

private func offsets(_ itemAlignment: FlowLayout.ItemAlignment) -> [CGPoint] {
    FlowLayout(horizontalSpacing: 8, verticalSpacing: 8, alignment: .leading, itemAlignment: itemAlignment)
        .layout(sizes: sizes, horizontalSpacing: 8, verticalSpacing: 8, containerWidth: 200)
        .offsets
}

/// The default, and what this layout has always done — an existing caller must render unchanged.
@Test func itemsSitAtTheTopOfTheirRowByDefault() {
    let placed = FlowLayout(horizontalSpacing: 8, verticalSpacing: 8, alignment: .leading)
        .layout(sizes: sizes, horizontalSpacing: 8, verticalSpacing: 8, containerWidth: 200)

    #expect(placed.offsets.map(\.y) == [0, 0, 0])
}

/// The reason the option exists: items of mixed heights should sit on one line rather than hang
/// from one.
@Test func centringPlacesEachItemInTheMiddleOfItsRow() {
    let ys = offsets(.center).map(\.y)

    #expect(ys == [20, 0, 10], "each item is offset by half the room its row leaves it")
}

@Test func bottomAlignmentRestsEachItemOnTheRowsBaseline() {
    #expect(offsets(.bottom).map(\.y) == [40, 0, 20])
}

/// Alignment moves items inside a row that is already as tall as its tallest, so the flow itself
/// is the same size whichever alignment it uses.
@Test func itemAlignmentDoesNotChangeTheSizeOfTheFlow() {
    let flowSizes = FlowLayout.ItemAlignment.allAlignments.map { alignment in
        FlowLayout(horizontalSpacing: 8, verticalSpacing: 8, alignment: .leading, itemAlignment: alignment)
            .layout(sizes: sizes, horizontalSpacing: 8, verticalSpacing: 8, containerWidth: 200)
            .size
    }

    #expect(Set(flowSizes.map(\.height)) == [60])
}

/// Rows wrap on width, and each row aligns its own items rather than the whole flow's tallest.
@Test func eachRowAlignsAgainstItsOwnTallestItem() {
    let wrapping = [
        CGSize(width: 60, height: 20),
        CGSize(width: 60, height: 40),
        CGSize(width: 60, height: 10),
        CGSize(width: 60, height: 30)
    ]

    let placed = FlowLayout(horizontalSpacing: 8, verticalSpacing: 8, alignment: .leading, itemAlignment: .center)
        .layout(sizes: wrapping, horizontalSpacing: 8, verticalSpacing: 8, containerWidth: 140)

    // Two rows of two. The first centres against 40, the second against 30, and the second row
    // starts a row height plus the spacing below the first.
    #expect(placed.offsets.map(\.y) == [10, 0, 58, 48])
}

private extension FlowLayout.ItemAlignment {
    static var allAlignments: [Self] { [.top, .center, .bottom] }
}
