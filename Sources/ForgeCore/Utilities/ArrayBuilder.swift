// Created by Dino Catalinac on 24.07.2026.

import Foundation

@resultBuilder
public enum ArrayBuilder<Element> {
    // MARK: - Expressions
    public static func buildExpression(_ first: Element) -> [Element] { [first] }
    public static func buildExpression(_ first: Element?) -> [Element] { first.map { [$0] } ?? [] }
    public static func buildExpression(_ first: [Element]) -> [Element] { first }
    public static func buildExpression(_ first: [Element]?) -> [Element] { first ?? [] }

    // MARK: - Blocks
    public static func buildBlock() -> [Element] { [] }
    public static func buildPartialBlock(first: [Element]) -> [Element] { first }
    public static func buildPartialBlock(accumulated: [Element], next: [Element]) -> [Element] { accumulated + next }

    // MARK: - Conditionals
    public static func buildEither(first: [Element]) -> [Element] { first }
    public static func buildEither(second: [Element]) -> [Element] { second }
    public static func buildIf(_ element: [Element]?) -> [Element] { element ?? [] }

    // MARK: - Never
    public static func buildPartialBlock(first: Never) -> [Element] {}
}
