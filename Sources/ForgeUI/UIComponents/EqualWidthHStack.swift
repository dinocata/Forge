// Created by Dino Catalinac on 09.10.2026.

import SwiftUI

/// A row that gives every subview the same width, filling the width it is offered.
///
/// Its ideal width is the widest subview's ideal width times the count, plus spacing, so inside a
/// `ViewThatFits` it is rejected as soon as any subview would truncate in its equal share. An
/// `HStack` of full-width subviews is not: it fits whenever their total does, then splits the width
/// evenly and cuts the longest label short.
///
/// ```swift
/// ViewThatFits(in: .horizontal) {
///     EqualWidthHStack(spacing: 8) { primaryButton; secondaryButton }
///     VStack(spacing: 8) { primaryButton; secondaryButton }
/// }
/// ```
public struct EqualWidthHStack: Layout {
    public var spacing: CGFloat

    public init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else {
            return .zero
        }

        let idealSizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let idealWidth = (idealSizes.map(\.width).max() ?? 0) * CGFloat(subviews.count) + totalSpacing(for: subviews)

        guard let width = proposal.width, width.isFinite else {
            return CGSize(width: idealWidth, height: idealSizes.map(\.height).max() ?? 0)
        }

        let itemProposal = ProposedViewSize(width: itemWidth(in: width, subviews: subviews), height: proposal.height)
        let height = subviews.map { $0.sizeThatFits(itemProposal).height }.max() ?? 0
        return CGSize(width: width, height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let width = itemWidth(in: bounds.width, subviews: subviews)
        let itemProposal = ProposedViewSize(width: width, height: bounds.height)
        var x = bounds.minX

        for subview in subviews {
            subview.place(at: CGPoint(x: x, y: bounds.midY), anchor: .leading, proposal: itemProposal)
            x += width + spacing
        }
    }

    private func totalSpacing(for subviews: Subviews) -> CGFloat {
        spacing * CGFloat(max(subviews.count - 1, 0))
    }

    private func itemWidth(in width: CGFloat, subviews: Subviews) -> CGFloat {
        max((width - totalSpacing(for: subviews)) / CGFloat(max(subviews.count, 1)), 0)
    }
}

#Preview {
    VStack(spacing: 24) {
        ForEach([320, 220] as [CGFloat], id: \.self) { width in
            ViewThatFits(in: .horizontal) {
                EqualWidthHStack { previewButtons }
                VStack(spacing: 8) { previewButtons }
            }
            .frame(width: width)
            .border(.secondary)
        }
    }
    .padding()
}

@ViewBuilder
private var previewButtons: some View {
    Text("Add Exercises")
        .lineLimit(1)
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(.blue.opacity(0.2), in: .capsule)

    Text("Suggest")
        .lineLimit(1)
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(.gray.opacity(0.2), in: .capsule)
}
