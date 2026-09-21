// Created by Dino Catalinac on 21.09.2026.

import SwiftUI

public extension View {
    /// Repeatedly animates the view between its resting look and a peak, both described by `pulse`.
    ///
    /// The view rests, with `isPeak` false, while inactive or while Reduce Motion is on.
    ///
    /// - Parameters:
    ///   - isActive: Whether the view pulses.
    ///   - animation: The curve of each half of the pulse, from rest to peak and back.
    ///   - pulse: The view at rest or at its peak.
    func pulsing<Pulsed: View>(
        isActive: Bool = true,
        animation: Animation = .easeInOut(duration: 1),
        @ViewBuilder _ pulse: @escaping (PlaceholderContentView<Self>, _ isPeak: Bool) -> Pulsed
    ) -> some View {
        PulsingView(content: self, isActive: isActive, animation: animation, pulse: pulse)
    }
}

/// A view rather than a `ViewModifier`, so `pulse` receives the caller's own view type like
/// `phaseAnimator` does. A modifier's content is SwiftUI's private `_ViewModifier_Content`, which
/// the public signature would then have to name, or erase to `AnyView`.
private struct PulsingView<Content: View, Pulsed: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let content: Content
    let isActive: Bool
    let animation: Animation
    let pulse: (PlaceholderContentView<Content>, Bool) -> Pulsed

    var body: some View {
        content.phaseAnimator(isActive && !reduceMotion ? [false, true] : [false]) { content, isPeak in
            pulse(content, isPeak)
        } animation: { _ in
            animation
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        Text("Opacity")
            .pulsing { content, isPeak in
                content.opacity(isPeak ? 0.4 : 1)
            }

        Text("Scale")
            .pulsing(animation: .easeInOut(duration: 0.6)) { content, isPeak in
                content.scaleEffect(isPeak ? 1.2 : 1)
            }

        Text("Inactive")
            .pulsing(isActive: false) { content, isPeak in
                content.opacity(isPeak ? 0.4 : 1)
            }
    }
}
