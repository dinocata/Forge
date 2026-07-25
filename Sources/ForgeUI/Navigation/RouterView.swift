//
//  RouterView.swift
//  AppUI
//
//  Created by Dino Čatalinac on 20.05.2026..
//

import SwiftUI

public struct RouterView<Destination: DestinationType, DestinationView: View>: View {
    @Environment(\.dismiss) var dismiss

    @Bindable var router: Router<Destination>

    let destinationType: Destination.Type
    let destinationResolver: (Destination) -> DestinationView

    public init(
        router: Router<Destination>,
        @ViewBuilder destinationResolver: @escaping (Destination) -> DestinationView
    ) {
        self.router = router
        self.destinationType = Destination.self
        self.destinationResolver = destinationResolver
    }

    public var body: some View {
        NavigationStack(path: $router.path) {
            destinationResolver(router.root)
                .navigationDestination(
                    for: destinationType
                ) { destination in
                    destinationResolver(destination)
                }
        }
        .sheet(item: $router.presentedSheet) { destination in
            destinationResolver(destination)
        }
        #if os(iOS)
        .fullScreenCover(item: $router.presentedFullscreenCover) { destination in
            destinationResolver(destination)
        }
        #endif
        .environment(router)
        .onChange(of: router.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
                router.shouldDismiss = false
            }
        }
    }
}
