//
//  LinearGradient+Angle.swift
//  AppUI
//
//  Created by Dino Čatalinac on 19.05.2026..
//

import SwiftUI

public extension LinearGradient {

    /// Initializes a `LinearGradient` from a CSS-style angle.
    /// CSS convention: 0° points up, increasing clockwise (90° = right, 180° = down, 270° = left).
    init(gradient: Gradient, angle: CGFloat) {
        let radians = (angle - 90) * .pi / 180

        let dx = cos(radians)
        let dy = -sin(radians)

        let start = UnitPoint(
            x: 0.5 - dx / 2,
            y: 0.5 + dy / 2
        )

        let end = UnitPoint(
            x: 0.5 + dx / 2,
            y: 0.5 - dy / 2
        )

        self.init(gradient: gradient, startPoint: start, endPoint: end)
    }
}
