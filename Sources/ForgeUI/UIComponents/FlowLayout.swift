//
//  FlowLayout.swift
//  AppUI
//
//  Created by Dino Čatalinac on 19.05.2026..
//

import SwiftUI

/// A `Layout` that flows subviews left-to-right, wrapping onto a new line
/// when the current row runs out of width. Useful for tag clouds, chip
/// collections, and suggested-prompt lists where item widths vary.
public struct FlowLayout: Layout {

    public enum RowAlignment: Sendable {
        case leading
        case center
        case trailing
    }

    /// Where an item sits in a row taller than itself.
    ///
    /// Only matters when a row mixes heights — uniform items, which is what a row of chips usually
    /// is, look the same whichever this is.
    public enum ItemAlignment: Sendable {
        case top
        case center
        case bottom
    }

    public var horizontalSpacing: CGFloat
    public var verticalSpacing: CGFloat
    public var alignment: RowAlignment
    public var itemAlignment: ItemAlignment

    /// - Parameter itemAlignment: Defaults to `.top`, which is where this layout has always put
    ///   items, so an existing caller renders unchanged.
    public init(
        horizontalSpacing: CGFloat = 8,
        verticalSpacing: CGFloat = 8,
        alignment: RowAlignment = .center,
        itemAlignment: ItemAlignment = .top
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.alignment = alignment
        self.itemAlignment = itemAlignment
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(
            sizes: sizes,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing,
            containerWidth: containerWidth
        ).size
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(
            sizes: sizes,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing,
            containerWidth: bounds.width
        ).offsets

        for (offset, subview) in zip(offsets, subviews) {
            subview.place(
                at: .init(
                    x: offset.x + bounds.minX,
                    y: offset.y + bounds.minY
                ),
                proposal: .unspecified
            )
        }
    }

    /// Where each row of a laid-out flow begins, how wide it came out, and how tall its tallest
    /// item is — everything the alignment pass needs to place the row's items along it.
    private struct Rows {
        var widths: [CGFloat] = []
        var heights: [CGFloat] = []
        var startIndices: [Int] = []
    }

    /// Internal rather than private so the geometry can be tested without fabricating SwiftUI's
    /// `Subviews`, which is the only other way into it.
    func layout(
        sizes: [CGSize],
        horizontalSpacing: CGFloat,
        verticalSpacing: CGFloat,
        containerWidth: CGFloat
    ) -> (offsets: [CGPoint], size: CGSize) {
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var rows = Rows()
        var maxWidth: CGFloat = 0

        guard !sizes.isEmpty else {
            return ([], CGSize(width: containerWidth, height: 0))
        }

        // Step 1: Calculate initial positions and track row widths
        for (index, size) in sizes.enumerated() {
            if currentX + size.width > containerWidth && currentX > 0 {
                rows.widths.append(currentX - horizontalSpacing)
                rows.heights.append(lineHeight)
                rows.startIndices.append(index)
                currentX = 0
                currentY += lineHeight + verticalSpacing
                lineHeight = 0
            }

            offsets.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentX)
        }

        // Final row
        rows.widths.append(currentX - horizontalSpacing)
        rows.heights.append(lineHeight)
        rows.startIndices.append(sizes.count)

        align(offsets: &offsets, sizes: sizes, rows: rows, containerWidth: containerWidth)

        let totalHeight = currentY + lineHeight
        return (offsets, CGSize(width: containerWidth, height: totalHeight))
    }

    /// Places each row's items along it: horizontally by ``alignment``, and vertically by
    /// ``itemAlignment`` within a row that is as tall as its tallest item — without which items of
    /// mixed heights hang from a line rather than sitting on one.
    private func align(
        offsets: inout [CGPoint],
        sizes: [CGSize],
        rows: Rows,
        containerWidth: CGFloat
    ) {
        for (rowIndex, rowWidth) in rows.widths.enumerated() {
            let offsetX: CGFloat
            switch alignment {
            case .leading:
                offsetX = 0
            case .center:
                offsetX = (containerWidth - rowWidth) / 2
            case .trailing:
                offsetX = containerWidth - rowWidth
            }

            let rowHeight = rows.heights[rowIndex]
            let startIndex = rowIndex == 0 ? 0 : rows.startIndices[rowIndex - 1]
            let endIndex = rows.startIndices[rowIndex]

            for subviewIndex in startIndex ..< endIndex where subviewIndex < offsets.count {
                offsets[subviewIndex].x += offsetX
                offsets[subviewIndex].y += verticalOffset(inRowOf: rowHeight, for: sizes[subviewIndex].height)
            }
        }
    }

    /// How far down its row an item of `height` sits.
    private func verticalOffset(inRowOf rowHeight: CGFloat, for height: CGFloat) -> CGFloat {
        let slack = rowHeight - height

        return switch itemAlignment {
        case .top: 0
        case .center: slack / 2
        case .bottom: slack
        }
    }
}
