// Created by Dino Catalinac on 21.09.2026.

import SwiftUI

public extension View {
    /// Scrolls this scroll view to keep a field marked ``revealedWhenFocused(_:)`` clear of the
    /// keyboard and anything else covering its bottom edge.
    ///
    /// For fields the system does not reveal on its own: it scrolls only the nearest scroll view
    /// around a focused field, which does nothing for one inside a nested horizontal scroll view.
    ///
    /// - Parameters:
    ///   - scrollPosition: The position this scroll view is bound to.
    ///   - spacing: The gap left between the field and what covers the bottom edge.
    func revealsFocusedField(at scrollPosition: Binding<ScrollPosition>, spacing: CGFloat = 16) -> some View {
        modifier(FocusedFieldRevealingModifier(scrollPosition: scrollPosition, spacing: spacing))
    }

    /// Marks this view as one ``revealsFocusedField(at:spacing:)`` keeps visible while `isFocused`.
    func revealedWhenFocused(_ isFocused: Bool) -> some View {
        modifier(FocusedFieldModifier(isFocused: isFocused))
    }
}

private struct FocusedField: Equatable {
    let id: UUID
    let frame: CGRect
}

private struct FocusedFieldKey: PreferenceKey {
    static let defaultValue: FocusedField? = nil

    static func reduce(value: inout FocusedField?, nextValue: () -> FocusedField?) {
        value = value ?? nextValue()
    }
}

private struct FocusedFieldModifier: ViewModifier {
    let isFocused: Bool

    /// Tells two fields apart, so focus moving between them reveals the second.
    @State private var id = UUID()
    @State private var frame: CGRect?

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect?.self) { isFocused ? $0.frame(in: .scrollView(axis: .vertical)) : nil } action: {
                frame = $0
            }
            .preference(key: FocusedFieldKey.self, value: frame.map { FocusedField(id: id, frame: $0) })
    }
}

private struct FocusedFieldRevealingModifier: ViewModifier {
    /// How far the scroll view has scrolled, measured as ``ScrollPosition`` measures it, and how much
    /// of it is left uncovered by the bars and the keyboard.
    private struct ScrollArea: Equatable {
        var offset: CGFloat = .zero
        var visibleHeight: CGFloat = .zero

        init() {}

        init(_ geometry: ScrollGeometry) {
            offset = geometry.contentOffset.y + geometry.contentInsets.top
            visibleHeight = geometry.containerSize.height
        }
    }

    @Binding var scrollPosition: ScrollPosition
    let spacing: CGFloat

    @State private var scrollArea = ScrollArea()
    @State private var focusedField: FocusedField?

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: ScrollArea.self, of: ScrollArea.init) { _, area in
                scrollArea = area
            }
            .onPreferenceChange(FocusedFieldKey.self) { focusedField = $0 }
            .onChange(of: focusedField?.id) { reveal() }
            .onChange(of: scrollArea.visibleHeight) { old, new in
                if new < old { reveal() }
            }
    }

    /// Deferred past the update that moved focus or raised the keyboard, whose own adjustment of the
    /// scroll view otherwise discards a scroll made within it.
    private func reveal() {
        Task {
            guard let frame = focusedField?.frame else { return }

            let obscuredHeight = frame.maxY + spacing - scrollArea.visibleHeight
            guard obscuredHeight > 0 else { return }

            withAnimation { scrollPosition.scrollTo(y: scrollArea.offset + obscuredHeight) }
        }
    }
}

#Preview {
    @Previewable @State var scrollPosition = ScrollPosition()
    @Previewable @State var text = Array(repeating: "", count: 12)
    @Previewable @FocusState var focusedIndex: Int?

    // The fields sit in a horizontal scroll view, which is where the system's own reveal stops.
    ScrollView {
        ScrollView(.horizontal) {
            VStack(spacing: 16) {
                ForEach(text.indices, id: \.self) { index in
                    TextField("Field \(index + 1)", text: $text[index])
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedIndex, equals: index)
                        .revealedWhenFocused(focusedIndex == index)
                }
            }
            .padding()
            .containerRelativeFrame(.horizontal)
        }
    }
    .scrollPosition($scrollPosition)
    .revealsFocusedField(at: $scrollPosition)
}
