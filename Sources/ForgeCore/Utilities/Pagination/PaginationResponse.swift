//
//  PaginationResponse.swift
//  Forge
//
//  Created by Dino Catalinac on 02.08.2026..
//

import Foundation

public struct PaginationResponse<Item, Cursor> {
    public let items: [Item]
    public let next: Cursor?
    public let previous: Cursor?

    public init(items: [Item], next: Cursor?, previous: Cursor?) {
        self.items = items
        self.next = next
        self.previous = previous
    }
}
