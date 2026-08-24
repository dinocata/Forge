import Foundation
import Testing
@testable import ForgeCore

private let utc = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC").forceUnwrap
    return calendar
}()

private func day(_ year: Int, _ month: Int, _ dayOfMonth: Int) -> Date {
    utc.date(from: DateComponents(year: year, month: month, day: dayOfMonth)).forceUnwrap
}

private let birthDate = day(1990, 6, 15)

@Test func ageCountsCompletedYears() {
    #expect(birthDate.age(asOf: day(2026, 6, 15)) == 36)
    #expect(birthDate.age(asOf: day(2026, 8, 24)) == 36)
}

/// A birthday is not reached until it arrives, so the day before still reads as the previous age.
@Test func ageDoesNotRoundUpToAnUnreachedBirthday() {
    #expect(birthDate.age(asOf: day(2026, 6, 14)) == 35)
}

/// The point of the parameter: the same birth date read at two moments gives two ages. Without it
/// every point of a trend would be aged to today.
@Test func ageIsMeasuredAgainstTheGivenMomentRatherThanNow() {
    #expect(birthDate.age(asOf: day(2016, 6, 15)) == 26)
    #expect(birthDate.age(asOf: day(2016, 6, 15)) != birthDate.age)
}

@Test func ageIsNegativeBeforeTheDateItCountsFrom() {
    #expect(birthDate.age(asOf: day(1988, 6, 15)) == -2)
}
