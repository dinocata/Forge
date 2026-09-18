//
//  View+Stretchy.swift
//  Robyn
//
//  Created by Dino Catalinac on 02.09.2025..
//

import SwiftUI

public extension View {
    /// Scales the view up from its bottom edge as a scroll view is pulled down past its top, so a
    /// header grows to fill the overscroll instead of leaving a gap above it.
    func stretchy() -> some View {
        visualEffect { effect, geometry in
            let currentHeight = geometry.size.height
            let scrollOffset = geometry.frame(in: .scrollView).minY
            let positiveOffset = max(0, scrollOffset)

            let newHeight = currentHeight + positiveOffset
            let scaleFactor = currentHeight > 0 ? newHeight / currentHeight : 1

            return effect.scaleEffect(
                x: scaleFactor, y: scaleFactor,
                anchor: .bottom
            )
        }
    }
}
