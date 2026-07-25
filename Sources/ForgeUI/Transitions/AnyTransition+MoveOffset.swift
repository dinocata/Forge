//
//  AnyTransition+MoveOffset.swift
//  AppUI
//
//  Created by Dino Čatalinac on 19.05.2026..
//

import SwiftUI

public extension AnyTransition {

    /// A move transition that allows specifying the offset amount in points.
    static func move(edge: Edge, offset: CGFloat) -> AnyTransition {
        let insertionOffset = offsetFor(edge: edge, offset: offset)
        let removalOffset = offsetFor(edge: edge, offset: offset)

        return .asymmetric(
            insertion: .offset(insertionOffset),
            removal: .offset(removalOffset)
        )
    }

    private static func offsetFor(edge: Edge, offset: CGFloat) -> CGSize {
        switch edge {
        case .leading: CGSize(width: -offset, height: 0)
        case .trailing: CGSize(width: offset, height: 0)
        case .top: CGSize(width: 0, height: -offset)
        case .bottom: CGSize(width: 0, height: offset)
        }
    }
}
