// Created by Dino Catalinac on 11.10.2026.

import SwiftUI

public extension View {
    /// Sizes the view to fit the largest of `reserved` as well as itself, without showing them.
    ///
    /// Lines up views that cannot share a container, such as one column across separate list rows:
    /// give each row the same candidates, typically every value the column can show, and the column
    /// takes the widest one's width everywhere. The reserved views follow Dynamic Type and
    /// localisation like any other, and are hidden from accessibility.
    ///
    /// ```swift
    /// Text(region.name)
    ///     .reservingSpace(alignment: .leading) {
    ///         ForEach(Region.allCases) { Text($0.name) }
    ///     }
    /// ```
    func reservingSpace<Reserved: View>(
        alignment: Alignment = .center,
        @ViewBuilder for reserved: () -> Reserved
    ) -> some View {
        ZStack(alignment: alignment) {
            reserved()
                .hidden()
                .accessibilityHidden(true)

            self
        }
    }
}

#Preview {
    let names = ["Chest", "Shoulders", "Back"]

    VStack(alignment: .leading, spacing: 8) {
        ForEach(names, id: \.self) { name in
            HStack {
                Text(name)
                    .reservingSpace(alignment: .leading) {
                        ForEach(names, id: \.self) { Text($0) }
                    }
                    .border(.secondary)

                Capsule()
                    .fill(.blue)
                    .frame(width: 80, height: 6)
            }
        }
    }
    .padding()
}
