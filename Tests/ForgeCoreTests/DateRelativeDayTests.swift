import Foundation
import Testing
@testable import ForgeCore

@Test func relativeDayFormattingUsesLocalizedNamedDates() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_000_000))
    let locale = Locale(identifier: "en_US")

    #expect(today.addingTimeInterval(-86_400).formattedRelativeDay(relativeTo: today, calendar: calendar, locale: locale) == "Yesterday")
    #expect(today.formattedRelativeDay(relativeTo: today, calendar: calendar, locale: locale) == "Today")
    #expect(today.addingTimeInterval(86_400).formattedRelativeDay(relativeTo: today, calendar: calendar, locale: locale) == "Tomorrow")
    #expect(today.addingTimeInterval(172_800).formattedRelativeDay(relativeTo: today, calendar: calendar, locale: locale) == nil)
}
