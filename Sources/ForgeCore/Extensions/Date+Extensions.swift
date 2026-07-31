import Foundation

public extension Date {

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay).forceUnwrap
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var age: Int {
        Calendar.current.dateComponents([.year], from: self, to: .now).year ?? 0
    }

    var daysAgo: Int {
        Calendar.current.dateComponents([.day], from: self, to: .now).day ?? 0
    }

    var fromUTCDate: Date {
        date(byAdding: .second, value: -TimeZone.current.secondsFromGMT())
    }

    var mondayBasedWeekDateInterval: DateInterval {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2

        guard let interval = calendar.dateInterval(of: .weekOfYear, for: self),
              let lastDayOfWeek = calendar.date(byAdding: .day, value: -1, to: interval.end) else {
            return .init(start: startOfDay, end: endOfDay)
        }

        return .init(start: interval.start.startOfDay, end: lastDayOfWeek.endOfDay)
    }

    func isSame(_ component: Calendar.Component, as referenceDate: Date = .now) -> Bool {
        Calendar.current.isDate(self, inSame: component, as: referenceDate)
    }

    func nextFull(_ component: Calendar.Component) -> Date {
        Calendar.current.dateInterval(of: component, for: self)?.end ?? date(byAdding: component, value: 1)
    }

    /// Returns a localized relative day name for yesterday, today, or tomorrow.
    ///
    /// Dates outside that range return `nil` so callers can apply a
    /// context-specific fallback format.
    func formattedRelativeDay(
        relativeTo referenceDate: Date = .now,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> String? {
        let startOfReferenceDay = calendar.startOfDay(for: referenceDate)
        let startOfDay = calendar.startOfDay(for: self)
        guard let dayOffset = calendar.dateComponents([.day], from: startOfReferenceDay, to: startOfDay).day,
              (-1...1).contains(dayOffset) else {
            return nil
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full
        formatter.formattingContext = .beginningOfSentence
        return formatter.localizedString(from: DateComponents(day: dayOffset))
    }
}

public extension Date {

    init(iso8601withFractionalSeconds parseInput: ParseStrategy.ParseInput) throws {
        try self.init(parseInput, strategy: .iso8601withFractionalSeconds)
    }

    func getDayDifference(from date: Date) -> Int {
        let calendar = Calendar.current
        let startOfFromDate = calendar.startOfDay(for: date)
        let startOfToDate = calendar.startOfDay(for: self)
        let dateComponents = calendar.dateComponents([.day, .hour, .minute], from: startOfFromDate, to: startOfToDate)
        return dateComponents.day ?? 0
    }

    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        calendar.dateComponents(Set(components), from: self)
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        calendar.component(component, from: self)
    }

    func date(byAdding components: Calendar.Component, value: Int) -> Date {
        Calendar.current.date(byAdding: components, value: value, to: self).forceUnwrap
    }

    func date(byAdding components: DateComponents) -> Date {
        Calendar.current.date(byAdding: components, to: self).forceUnwrap
    }
}

public extension ParseStrategy where Self == Date.ISO8601FormatStyle {
    static var iso8601withFractionalSeconds: Self { .init(includingFractionalSeconds: true) }
    static var iso8601FullDate: Self { .init().year().month().day() }
}

public extension FormatStyle where Self == Date.ISO8601FormatStyle {
    static var iso8601withFractionalSeconds: Date.ISO8601FormatStyle { .init(includingFractionalSeconds: true) }
    static var iso8601FullDate: Date.ISO8601FormatStyle { .init().year().month().day() }
}

public extension Date {
    var asISOString: String {
        formatted(.iso8601.year().month().day())
    }
}
