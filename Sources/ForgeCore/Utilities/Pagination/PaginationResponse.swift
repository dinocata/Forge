//
//  PaginationResponse.swift
//  Forge
//
//  Created by Dino Catalinac on 02.08.2026..
//

import Foundation

public struct PaginationResponse<Item, Cursor> {
    let items: [Item]
    let next: Cursor?
    let previous: Cursor?
}
