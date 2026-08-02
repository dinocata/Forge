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

extension PaginationResponse: Sendable where Item: Sendable, Cursor: Sendable {}
extension PaginationResponse: Decodable where Item: Decodable, Cursor: Decodable {}
extension PaginationResponse: Hashable where Item: Hashable, Cursor: Hashable {}
extension PaginationResponse: Equatable where Item: Equatable, Cursor: Equatable {}
