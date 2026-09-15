// Created by Dino Catalinac on 15.09.2026.

import Testing
@testable import ForgeCore

private struct Sample: Equatable {
    let position: Int
}

@Test func elementsBracketingFindsAdjacentValues() throws {
    let samples = [0, 10, 20, 30].map(Sample.init)

    let result = try #require(samples.elementsBracketing(14, by: \.position))

    #expect(result.lower == Sample(position: 10))
    #expect(result.upper == Sample(position: 20))
}

@Test func elementsBracketingIncludesCollectionBounds() throws {
    let samples = [0, 10, 20, 30].map(Sample.init)

    let lower = try #require(samples.elementsBracketing(0, by: \.position))
    let upper = try #require(samples.elementsBracketing(30, by: \.position))

    #expect(lower.lower == Sample(position: 0))
    #expect(lower.upper == Sample(position: 10))
    #expect(upper.lower == Sample(position: 20))
    #expect(upper.upper == Sample(position: 30))
}

@Test func elementsBracketingReturnsExactInteriorValueAsUpperElement() throws {
    let samples = [0, 10, 20, 30].map(Sample.init)

    let result = try #require(samples.elementsBracketing(20, by: \.position))

    #expect(result.lower == Sample(position: 10))
    #expect(result.upper == Sample(position: 20))
}

@Test func elementsBracketingWorksWithArraySlices() throws {
    let samples = [0, 10, 20, 30, 40].map(Sample.init)[1...3]

    let result = try #require(samples.elementsBracketing(24, by: \.position))

    #expect(result.lower == Sample(position: 20))
    #expect(result.upper == Sample(position: 30))
}

@Test(arguments: [-1, 31])
func elementsBracketingRejectsValuesOutsideTheCollection(value: Int) {
    let samples = [0, 10, 20, 30].map(Sample.init)

    #expect(samples.elementsBracketing(value, by: \.position) == nil)
}

@Test(arguments: [[], [10]])
func elementsBracketingRequiresTwoElements(values: [Int]) {
    let samples = values.map(Sample.init)

    #expect(samples.elementsBracketing(10, by: \.position) == nil)
}
