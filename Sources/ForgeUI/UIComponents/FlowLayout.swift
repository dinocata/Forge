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

    public var horizontalSpacing: CGFloat
    public var verticalSpacing: CGFloat
    public var alignment: RowAlignment

    public init(
        horizontalSpacing: CGFloat = 8,
        verticalSpacing: CGFloat = 8,
        alignment: RowAlignment = .center
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.alignment = alignment
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

    private func layout(
        sizes: [CGSize],
        horizontalSpacing: CGFloat,
        verticalSpacing: CGFloat,
        containerWidth: CGFloat
    ) -> (offsets: [CGPoint], size: CGSize) {
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var rowWidths: [CGFloat] = []
        var rowStartIndices: [Int] = []
        var maxWidth: CGFloat = 0

        guard !sizes.isEmpty else {
            return ([], CGSize(width: containerWidth, height: 0))
        }

        // Step 1: Calculate initial positions and track row widths
        for (index, size) in sizes.enumerated() {
            if currentX + size.width > containerWidth && currentX > 0 {
                rowWidths.append(currentX - horizontalSpacing)
                rowStartIndices.append(index)
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
        rowWidths.append(currentX - horizontalSpacing)
        rowStartIndices.append(sizes.count)

        // Step 2: Adjust x-coordinates based on alignment
        for (rowIndex, rowWidth) in rowWidths.enumerated() {
            let offsetX: CGFloat
            switch alignment {
            case .leading:
                offsetX = 0
            case .center:
                offsetX = (containerWidth - rowWidth) / 2
            case .trailing:
                offsetX = containerWidth - rowWidth
            }

            let startIndex = rowIndex == 0 ? 0 : rowStartIndices[rowIndex - 1]
            let endIndex = rowStartIndices[rowIndex]
            for subviewIndex in startIndex ..< endIndex where subviewIndex < offsets.count {
                offsets[subviewIndex].x += offsetX
            }
        }

        let totalHeight = currentY + lineHeight
        return (offsets, CGSize(width: containerWidth, height: totalHeight))
    }
}
