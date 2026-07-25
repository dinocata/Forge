//
//  View+Style.swift
//  AppUI
//
//  Created by Dino Čatalinac on 19.05.2026..
//

import SwiftUI

public extension View {

    /// Clips the view to a `RoundedRectangle` with a design-system corner
    /// radius. Use `.clipShape(.capsule)` for fully-pill shapes instead.
    func roundedCorner(radius: CornerRadius) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius.value))
    }

    /// Clips the view to a `RoundedRectangle` and strokes its outline with the
    /// given style. One call replaces a `.clipShape(...)` + `.overlay { ... }`
    /// pair.
    func roundedBorder<BorderStyle: ShapeStyle>(
        cornerRadius: CornerRadius,
        borderStyle: BorderStyle,
        borderWidth: CGFloat = 1
    ) -> some View {
        shapedBorder(
            RoundedRectangle(cornerRadius: cornerRadius.value),
            borderStyle: borderStyle,
            borderWidth: borderWidth
        )
    }

    /// Clips the view to an arbitrary `Shape` and strokes its outline with the
    /// given style.
    func shapedBorder<ClipShape: Shape, BorderStyle: ShapeStyle>(
        _ shape: ClipShape,
        borderStyle: BorderStyle,
        borderWidth: CGFloat = 1
    ) -> some View {
        clipShape(shape)
            .overlay {
                shape.stroke(borderStyle, lineWidth: borderWidth)
            }
    }
}
