import Foundation

public extension Date {
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
