//
//  ValidationStatePreferenceKey.swift
//  AppCore
//
//  Created by Dino Catalinac on 15.09.2025..
//
//  Bubbles up "is there a pending or failed validation somewhere in the
//  view subtree?" as a Bool through SwiftUI's preference system. Used
//  by parent containers (e.g. "Continue" buttons that should disable
//  while validation is in-flight or failing).

import SwiftUI

public struct ValidationStatePreferenceKey: PreferenceKey {
    public static let defaultValue: Bool = false

    public static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}
