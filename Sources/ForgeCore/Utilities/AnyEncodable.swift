// Created by Dino Catalinac on 23.07.2026.

import Foundation

public struct AnyEncodable: Encodable {
    private let encodable: Encodable

    public init(_ encodable: Encodable) {
        self.encodable = encodable
    }

    public func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}

public extension Encodable {
    var wrapToAnyEncodable: AnyEncodable {
        .init(self)
    }
}
