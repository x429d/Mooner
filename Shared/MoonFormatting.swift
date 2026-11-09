import Foundation

enum MoonFormat {
    private static let englishDecimal = Locale(identifier: "en_US")
    private static let englishDayMonth = Locale(identifier: "en_GB")

    /// One decimal place with an English decimal separator: `8.2`, never `8,2`.
    static func decimal(_ value: Double, fractionDigits: Int = 1) -> String {
        value.formatted(
            .number
                .locale(englishDecimal)
                .precision(.fractionLength(fractionDigits))
        )
    }

    /// `24 Nov`
    static func dayMonth(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .day()
                .month(.abbreviated)
                .locale(englishDayMonth)
        )
    }

    /// `in 7d`, `in 6h`, or `today`.
    static func countdown(_ date: Date, from now: Date) -> String {
        let seconds = date.timeIntervalSince(now)
        if seconds <= 0 { return "today" }

        if seconds < 86_400 {
            let hours = max(1, Int((seconds / 3_600).rounded()))
            return "in \(hours)h"
        }

        let days = max(1, Int((seconds / 86_400).rounded()))
        return "in \(days)d"
    }

    /// `Full moon in 7 days`
    static func fullMoonPhrase(_ date: Date, from now: Date) -> String {
        let seconds = date.timeIntervalSince(now)
        if seconds <= 0 { return "Full moon today" }

        let days = max(1, Int((seconds / 86_400).rounded()))
        return "Full moon in \(days) \(days == 1 ? "day" : "days")"
    }
}

extension MoonSnapshot {
    var isWaxing: Bool { phaseFraction < 0.5 }
    var trendWord: String { isWaxing ? "Waxing" : "Waning" }
    var trendArrow: String { isWaxing ? "↑" : "↓" }
    var ageText: String { MoonFormat.decimal(age) }

    var fullMoonCountdown: String {
        MoonFormat.countdown(nextFullMoon, from: date)
    }

    var fullMoonPhrase: String {
        MoonFormat.fullMoonPhrase(nextFullMoon, from: date)
    }

    var fullMoonCountdownAndDate: String {
        "\(fullMoonCountdown) · \(MoonFormat.dayMonth(nextFullMoon))"
    }

    /// The next phases for the large forecast, skipping the current principal
    /// phase when the snapshot sits almost exactly on top of it.
    var forecastPhases: [MoonPhaseEvent] {
        let twoDays: TimeInterval = 2 * 86_400
        return upcomingPhases.filter { event in
            !(event.kind == name && abs(event.date.timeIntervalSince(date)) < twoDays)
        }
    }
}
