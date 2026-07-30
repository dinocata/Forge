// Created by Dino Catalinac on 30.07.2026.

import ForgeCore
import SwiftUI

@MainActor
public extension Binding {
    func elementBinding<Element: Identifiable & Sendable>(
        for element: Element
    ) -> Binding<Element>
    where Value == IdentifiedArrayOf<Element> {
        let id = element.id

        return Binding<Element>(
            get: {
                wrappedValue[id: id] ?? element
            },
            set: { newValue in
                guard newValue.id == id, wrappedValue[id: id] != nil else {
                    return
                }

                wrappedValue[id: id] = newValue
            }
        )
    }
}
