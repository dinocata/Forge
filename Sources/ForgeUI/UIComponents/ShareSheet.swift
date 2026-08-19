// Created by Dino Catalinac on 19.08.2026.

#if canImport(UIKit)
import SwiftUI
import UIKit

/// The system share sheet, presented from state rather than from a link.
///
/// `ShareLink` is the right tool when what you are sharing exists before the view
/// does. It is the wrong one when the thing has to be produced first — a file
/// generated on demand, a rendered image — because it needs its items when it is
/// *constructed*. Presenting this from `.sheet(item:)` lets the work finish and
/// the result drive the presentation.
///
/// ```swift
/// .sheet(item: $export) { export in
///     ShareSheet(items: [export.url]) { cleanUp() }
/// }
/// ```
public struct ShareSheet: UIViewControllerRepresentable {

    private let items: [Any]
    private let onFinish: () -> Void

    /// - Parameters:
    ///   - items: what to share — URLs, strings, images, anything `UIActivityViewController` accepts.
    ///   - onFinish: called once the sheet is done, whether it shared or was dismissed.
    ///     The place to delete a temporary file, since an activity reads it while
    ///     it runs and `onDisappear` would fire while a copy may still be in flight.
    public init(items: [Any], onFinish: @escaping () -> Void = {}) {
        self.items = items
        self.onFinish = onFinish
    }

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in onFinish() }
        return controller
    }

    public func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
#endif
