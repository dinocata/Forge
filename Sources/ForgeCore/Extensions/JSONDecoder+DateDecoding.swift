// Created by Dino Catalinac on 23.07.2026.

import Foundation

extension JSONDecoder.DateDecodingStrategy {
    public static let iso8601withOptionalFractionalSeconds: Self = custom {
        let string: String = try $0.singleValueContainer().decode(String.self)
        do {
            return try .init(string, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true))
        } catch {
            do {
                return try .init(string, strategy: .iso8601)
            } catch {
                guard let date = try? Date(string, strategy: .dateTime.year().month().day()) else {
                    throw error
                }
                return date
            }
        }
    }
}
