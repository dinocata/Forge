//
//  View+AsButton.swift
//  AppUI
//
//  Created by Dino Čatalinac on 19.05.2026..
//

import SwiftUI

public extension View {

    func asButton(role: ButtonRole? = nil, action: @escaping @MainActor () -> Void) -> Button<Self> {
        Button(role: role, action: action, label: { self })
    }
}
