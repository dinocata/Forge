// Created by Dino Catalinac on 22.09.2026.

import SwiftUI

private struct AdaptiveSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ViewBuilder let sheetContent: () -> SheetContent

    @State private var contentHeight: CGFloat = .zero

    func body(content: Content) -> some View {
        content.background {
            sheetContent()
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height.rounded(.up)
                } action: { height in
                    guard contentHeight != height else { return }
                    contentHeight = height
                }
                .hidden()
                .sheet(isPresented: $isPresented) {
                    ScrollView {
                        sheetContent()
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .presentationDetents(contentHeight > 0 ? [.height(contentHeight)] : [.medium])
                }
                .id(contentHeight)
        }
    }
}

public extension View {
    /// Presents a bottom sheet sized to the content measured before presentation.
    ///
    /// Oversized content remains scrollable when the system constrains the requested detent.
    func adaptiveSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(AdaptiveSheetModifier(isPresented: isPresented, sheetContent: content))
    }
}
