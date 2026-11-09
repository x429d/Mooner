import Foundation

/// A compact, dependency-free implementation of the Moon's phase.
///
/// Longitude and latitude series follow Jean Meeus, *Astronomical Algorithms*
/// (2nd ed.). The result is accurate to well under one percent for the
/// illuminated fraction, which is far more than a widget needs.
enum LunarMath {
    static let synodicMonth = 29.530588853
    static let degreesToRadians = Double.pi / 180.0
    static let julianDayUnixEpoch = 2_440_587.5
    static let julianDayJ2000 = 2_451_545.0

    // MARK: - Public state

    /// 0 = new moon, 0.25 = first quarter, 0.5 = full moon, 0.75 = last quarter.
    static func phaseFraction(at date: Date) -> Double {
        let T = julianCenturies(at: date)
        var delta = (moonEclipticLongitude(T) - sunEclipticLongitude(T))
            .truncatingRemainder(dividingBy: 360)
        if delta < 0 { delta += 360 }
        return delta / 360
    }

    static func illuminatedFraction(at date: Date) -> Double {
        let T = julianCenturies(at: date)
        let deltaLongitude = (moonEclipticLongitude(T) - sunEclipticLongitude(T))
        let latitude = moonEclipticLatitude(T)
        let cosElongation =
            cos(latitude * degreesToRadians) *
            cos(deltaLongitude * degreesToRadians)
        return (1 - cosElongation) / 2
    }

    // MARK: - Event dates

    /// The next time the Moon reaches the given fraction of its cycle.
    static func nextPhase(after date: Date, target: Double) -> Date {
        let current = phaseFraction(at: date)
        var delta = target - current
        if delta <= 0 { delta += 1 }
        let estimate = date.addingTimeInterval(delta * synodicMonth * 86_400)
        return phaseCrossing(near: estimate, target: target)
    }

    /// The latest new moon at or before the given date.
    static func previousNewMoon(before date: Date) -> Date {
        let fraction = phaseFraction(at: date)
        let estimate = date.addingTimeInterval(-fraction * synodicMonth * 86_400)
        return phaseCrossing(near: estimate, target: 0)
    }

    // MARK: - Root finding

    private static func phaseCrossing(near estimate: Date, target: Double) -> Date {
        var low = estimate.addingTimeInterval(-2 * 86_400)
        var high = estimate.addingTimeInterval(2 * 86_400)
        var lowValue = signedPhaseDifference(at: low, target: target)
        var highValue = signedPhaseDifference(at: high, target: target)

        var attempts = 0
        while !(lowValue <= 0 && highValue >= 0) && attempts < 5 {
            low = low.addingTimeInterval(-3 * 86_400)
            high = high.addingTimeInterval(3 * 86_400)
            lowValue = signedPhaseDifference(at: low, target: target)
            highValue = signedPhaseDifference(at: high, target: target)
            attempts += 1
        }

        guard lowValue <= 0 && highValue >= 0 else { return estimate }

        for _ in 0..<52 {
            let middle = low.addingTimeInterval(high.timeIntervalSince(low) / 2)
            if signedPhaseDifference(at: middle, target: target) < 0 {
                low = middle
            } else {
                high = middle
            }
        }
        return low.addingTimeInterval(high.timeIntervalSince(low) / 2)
    }

    /// A value in (-0.5, 0.5] that is monotonic while crossing a phase target.
    private static func signedPhaseDifference(at date: Date, target: Double) -> Double {
        var difference = (phaseFraction(at: date) - target)
            .truncatingRemainder(dividingBy: 1)
        if difference > 0.5 { difference -= 1 }
        if difference <= -0.5 { difference += 1 }
        return difference
    }

    // MARK: - Time

    private static func julianCenturies(at date: Date) -> Double {
        let julianDay = date.timeIntervalSince1970 / 86_400 + julianDayUnixEpoch
        return (julianDay - julianDayJ2000) / 36_525
    }

    // MARK: - Solar coordinates

    private static func sunEclipticLongitude(_ T: Double) -> Double {
        let L0 = 280.46646 + 36_000.76983 * T + 0.0003032 * T * T
        let M = 357.52911 + 35_999.05029 * T - 0.0001537 * T * T
        let C =
            (1.914602 - 0.004817 * T - 0.000014 * T * T) * sinDegrees(M) +
            (0.019993 - 0.000101 * T) * sinDegrees(2 * M) +
            0.000289 * sinDegrees(3 * M)
        return L0 + C
    }

    // MARK: - Lunar coordinates

    private static func moonEclipticLongitude(_ T: Double) -> Double {
        let Lp = 218.3164477 + 481_267.88123421 * T - 0.0015786 * T * T
            + pow(T, 3) / 538_841 - pow(T, 4) / 65_194_000
        let D = 297.8501921 + 445_267.1114034 * T - 0.0018819 * T * T
            + pow(T, 3) / 545_868 - pow(T, 4) / 113_065_000
        let M = 357.5291092 + 35_999.0502909 * T - 0.0001536 * T * T
            + pow(T, 3) / 24_490_000
        let Mp = 134.9633964 + 477_198.8675055 * T + 0.0087414 * T * T
            + pow(T, 3) / 69_699 - pow(T, 4) / 14_712_000
        let F = 93.2720950 + 483_202.0175233 * T - 0.0036539 * T * T
            - pow(T, 3) / 3_526_000 + pow(T, 4) / 863_310_000
        let A1 = 119.75 + 131.849 * T
        let A2 = 53.09 + 479_264.290 * T
        let E = 1 - 0.002516 * T - 0.0000074 * T * T

        let sum =
            6_288_774 * sinDegrees(Mp)
            + 1_274_027 * sinDegrees(2 * D - Mp)
            + 658_314 * sinDegrees(2 * D)
            + 213_618 * sinDegrees(2 * Mp)
            - 185_116 * sinDegrees(M) * E
            - 114_332 * sinDegrees(2 * F)
            + 58_793 * sinDegrees(2 * D - 2 * Mp)
            + 57_066 * sinDegrees(2 * D - M - Mp) * E
            + 53_322 * sinDegrees(2 * D + Mp)
            + 45_758 * sinDegrees(2 * D - M) * E
            - 40_923 * sinDegrees(M - Mp) * E
            - 34_720 * sinDegrees(D)
            - 30_383 * sinDegrees(M + Mp) * E
            + 15_327 * sinDegrees(2 * D - 2 * F)
            - 12_528 * sinDegrees(Mp + 2 * F)
            + 10_980 * sinDegrees(Mp - 2 * F)
            + 10_675 * sinDegrees(4 * D - Mp)
            + 10_034 * sinDegrees(3 * Mp)
            + 8_548 * sinDegrees(4 * D - 2 * Mp)
            - 7_888 * sinDegrees(2 * D + M - Mp) * E
            - 6_766 * sinDegrees(2 * D + M) * E
            - 5_163 * sinDegrees(D - Mp)
            + 4_987 * sinDegrees(D + M) * E
            + 4_036 * sinDegrees(2 * D - M + Mp) * E
            + 3_994 * sinDegrees(2 * D + 2 * Mp)
            + 3_861 * sinDegrees(4 * D)
            + 3_665 * sinDegrees(2 * D - 3 * Mp)
            - 2_689 * sinDegrees(M - 2 * Mp) * E
            - 2_602 * sinDegrees(2 * D - Mp + 2 * F)
            + 2_390 * sinDegrees(2 * D - M - 2 * Mp) * E
            - 2_348 * sinDegrees(D + Mp)
            + 2_236 * sinDegrees(2 * D - 2 * M) * E * E
            - 2_120 * sinDegrees(M + 2 * Mp) * E
            - 2_069 * sinDegrees(2 * M) * E * E
            + 2_048 * sinDegrees(2 * D - 2 * M - Mp) * E * E
            - 1_773 * sinDegrees(2 * D + Mp - 2 * F)
            - 1_595 * sinDegrees(2 * D + 2 * F)
            + 1_215 * sinDegrees(4 * D - M - Mp) * E
            - 1_110 * sinDegrees(2 * Mp + 2 * F)
            - 892 * sinDegrees(3 * D - Mp)
            - 810 * sinDegrees(2 * D + M + Mp) * E
            + 759 * sinDegrees(4 * D - M - 2 * Mp) * E
            - 713 * sinDegrees(2 * M - Mp) * E * E
            - 700 * sinDegrees(2 * D + 2 * M - Mp) * E * E
            + 691 * sinDegrees(2 * D + M - 2 * Mp) * E
            + 596 * sinDegrees(2 * D - M - 2 * F) * E
            + 549 * sinDegrees(4 * D + Mp)
            + 537 * sinDegrees(4 * Mp)
            + 520 * sinDegrees(4 * D - M) * E
            - 487 * sinDegrees(D - 2 * Mp)
            - 399 * sinDegrees(2 * D + M - 2 * F) * E
            - 381 * sinDegrees(2 * Mp - 2 * F)
            + 351 * sinDegrees(D + M + Mp) * E
            - 340 * sinDegrees(3 * D - 2 * Mp)
            + 330 * sinDegrees(4 * D - 3 * Mp)
            + 327 * sinDegrees(2 * D - M + 2 * Mp) * E
            + 299 * sinDegrees(D + M - Mp) * E
            + 294 * sinDegrees(2 * D + 3 * Mp)

        let corrections =
            3_958 * sinDegrees(A1)
            + 1_962 * sinDegrees(Lp - F)
            + 318 * sinDegrees(A2)

        return Lp + (sum + corrections) / 1_000_000
    }

    private static func moonEclipticLatitude(_ T: Double) -> Double {
        let Lp = 218.3164477 + 481_267.88123421 * T - 0.0015786 * T * T
            + pow(T, 3) / 538_841 - pow(T, 4) / 65_194_000
        let D = 297.8501921 + 445_267.1114034 * T - 0.0018819 * T * T
            + pow(T, 3) / 545_868 - pow(T, 4) / 113_065_000
        let M = 357.5291092 + 35_999.0502909 * T - 0.0001536 * T * T
            + pow(T, 3) / 24_490_000
        let Mp = 134.9633964 + 477_198.8675055 * T + 0.0087414 * T * T
            + pow(T, 3) / 69_699 - pow(T, 4) / 14_712_000
        let F = 93.2720950 + 483_202.0175233 * T - 0.0036539 * T * T
            - pow(T, 3) / 3_526_000 + pow(T, 4) / 863_310_000
        let A1 = 119.75 + 131.849 * T
        let A3 = 313.45 + 481_266.484 * T

        let sum =
            5_128_122 * sinDegrees(F)
            + 280_602 * sinDegrees(Mp + F)
            + 277_693 * sinDegrees(Mp - F)
            + 173_237 * sinDegrees(2 * D - F)
            + 55_413 * sinDegrees(2 * D - Mp + F)
            + 46_271 * sinDegrees(2 * D - Mp - F)
            + 32_573 * sinDegrees(2 * D + F)
            + 17_198 * sinDegrees(2 * Mp + F)
            + 9_266 * sinDegrees(2 * D + Mp - F)
            + 8_822 * sinDegrees(2 * Mp - F)
            + 8_216 * sinDegrees(2 * D - M - F)
            + 4_324 * sinDegrees(2 * D - 2 * Mp - F)
            + 4_200 * sinDegrees(2 * D + Mp + F)
            - 3_359 * sinDegrees(2 * D + M - F)
            + 2_463 * sinDegrees(2 * D - M - Mp + F)
            + 2_211 * sinDegrees(2 * D - M - Mp - F)
            + 2_065 * sinDegrees(2 * D - Mp)
            - 1_870 * sinDegrees(M - F)
            - 1_828 * sinDegrees(2 * D - M + Mp - F)
            - 1_794 * sinDegrees(M + F)
            - 1_749 * sinDegrees(3 * Mp + F)
            - 1_565 * sinDegrees(M - Mp - F)
            - 1_491 * sinDegrees(D + F)
            - 1_475 * sinDegrees(D - F)
            - 1_410 * sinDegrees(M + Mp + F)
            - 1_344 * sinDegrees(M + Mp - F)
            - 1_335 * sinDegrees(D + Mp - F)
            + 1_107 * sinDegrees(2 * D - 2 * F)
            + 1_021 * sinDegrees(2 * D - Mp - 2 * F)
            + 833 * sinDegrees(2 * D + Mp + 2 * F)
            + 777 * sinDegrees(2 * D + Mp)
            + 671 * sinDegrees(2 * D - M - Mp)
            + 607 * sinDegrees(D - Mp + F)
            + 596 * sinDegrees(D - Mp - F)
            + 491 * sinDegrees(2 * D - Mp + M)
            - 451 * sinDegrees(D + M - F)
            + 439 * sinDegrees(Mp + 2 * F)
            + 422 * sinDegrees(2 * D + 2 * Mp + F)
            + 421 * sinDegrees(2 * D - 3 * Mp - F)
            - 366 * sinDegrees(D + M + Mp - F)
            - 351 * sinDegrees(D + M + Mp + F)
            + 331 * sinDegrees(2 * D + M + F)
            + 315 * sinDegrees(2 * D - M + 2 * Mp - F)
            + 302 * sinDegrees(2 * D - M - 2 * Mp + F)
            - 283 * sinDegrees(M + 2 * Mp + F)
            - 229 * sinDegrees(2 * D + M - Mp - F)
            + 223 * sinDegrees(D + M - Mp + F)
            + 223 * sinDegrees(D + M - Mp - F)
            - 220 * sinDegrees(M + 2 * Mp - F)
            - 220 * sinDegrees(2 * D + M - Mp)
            - 185 * sinDegrees(D + M + Mp)
            + 181 * sinDegrees(2 * D - M - 2 * Mp - F)
            - 177 * sinDegrees(M + 2 * Mp)
            + 176 * sinDegrees(4 * D - Mp - F)
            + 166 * sinDegrees(4 * D - Mp - 2 * F)
            + 164 * sinDegrees(D + Mp + 2 * F)
            + 132 * sinDegrees(4 * D - Mp)
            - 119 * sinDegrees(D - Mp)
            + 115 * sinDegrees(4 * D - 2 * Mp - F)
            + 107 * sinDegrees(4 * D - 2 * Mp - 2 * F)

        let corrections =
            -2_235 * sinDegrees(Lp)
            + 382 * sinDegrees(A3)
            + 175 * sinDegrees(A1 - F)
            + 175 * sinDegrees(A1 + F)
            + 127 * sinDegrees(Lp - Mp)
            - 115 * sinDegrees(Lp + Mp)

        return (sum + corrections) / 1_000_000
    }

    private static func sinDegrees(_ degrees: Double) -> Double {
        Foundation.sin(degrees * degreesToRadians)
    }
}

// MARK: - Phase names

enum MoonPhaseName: String, CaseIterable, Sendable {
    case newMoon
    case waxingCrescent
    case firstQuarter
    case waxingGibbous
    case fullMoon
    case waningGibbous
    case lastQuarter
    case waningCrescent

    var title: String {
        switch self {
        case .newMoon: return "New Moon"
        case .waxingCrescent: return "Waxing Crescent"
        case .firstQuarter: return "First Quarter"
        case .waxingGibbous: return "Waxing Gibbous"
        case .fullMoon: return "Full Moon"
        case .waningGibbous: return "Waning Gibbous"
        case .lastQuarter: return "Last Quarter"
        case .waningCrescent: return "Waning Crescent"
        }
    }

    var shortTitle: String {
        switch self {
        case .newMoon: return "New"
        case .waxingCrescent: return "Waxing crescent"
        case .firstQuarter: return "First quarter"
        case .waxingGibbous: return "Waxing gibbous"
        case .fullMoon: return "Full"
        case .waningGibbous: return "Waning gibbous"
        case .lastQuarter: return "Last quarter"
        case .waningCrescent: return "Waning crescent"
        }
    }

    /// The exact cycle position represented by this principal phase.
    var targetFraction: Double {
        switch self {
        case .newMoon: return 0
        case .firstQuarter: return 0.25
        case .fullMoon: return 0.5
        case .lastQuarter: return 0.75
        default: return 0
        }
    }

    static func current(for fraction: Double) -> MoonPhaseName {
        let phase = fraction - floor(fraction)
        if phase < 0.01 || phase >= 0.99 { return .newMoon }
        if phase < 0.24 { return .waxingCrescent }
        if phase < 0.26 { return .firstQuarter }
        if phase < 0.49 { return .waxingGibbous }
        if phase < 0.51 { return .fullMoon }
        if phase < 0.74 { return .waningGibbous }
        if phase < 0.76 { return .lastQuarter }
        return .waningCrescent
    }
}

struct MoonPhaseEvent: Identifiable, Sendable {
    let kind: MoonPhaseName
    let date: Date

    var id: String { "\(kind.rawValue)-\(date.timeIntervalSince1970)" }
}

// MARK: - Snapshot

struct MoonSnapshot: Sendable {
    let date: Date
    let phaseFraction: Double
    let illumination: Double
    let age: Double
    let name: MoonPhaseName
    let previousNewMoon: Date
    let nextNewMoon: Date
    let nextFullMoon: Date
    let upcomingPhases: [MoonPhaseEvent]

    init(date: Date) {
        self.date = date
        let phase = LunarMath.phaseFraction(at: date)
        phaseFraction = phase
        illumination = LunarMath.illuminatedFraction(at: date)
        name = MoonPhaseName.current(for: phase)

        let previousNew = LunarMath.previousNewMoon(before: date)
        previousNewMoon = previousNew
        age = max(0, date.timeIntervalSince(previousNew) / 86_400)

        let events = [
            MoonPhaseEvent(kind: .newMoon, date: LunarMath.nextPhase(after: date, target: 0)),
            MoonPhaseEvent(kind: .firstQuarter, date: LunarMath.nextPhase(after: date, target: 0.25)),
            MoonPhaseEvent(kind: .fullMoon, date: LunarMath.nextPhase(after: date, target: 0.5)),
            MoonPhaseEvent(kind: .lastQuarter, date: LunarMath.nextPhase(after: date, target: 0.75))
        ].sorted { $0.date < $1.date }

        upcomingPhases = Array(events.prefix(4))
        nextNewMoon = events.first(where: { $0.kind == .newMoon })?.date ?? date
        nextFullMoon = events.first(where: { $0.kind == .fullMoon })?.date ?? date
    }

    /// Rounded illumination percentage, with a sliver always reading as at least 1%.
    var illuminationPercent: Int {
        let rounded = Int((illumination * 100).rounded())
        if illumination > 0 && rounded == 0 { return 1 }
        return min(100, max(0, rounded))
    }

    /// Short label for the next upcoming principal phase.
    var nextPhase: MoonPhaseEvent? { upcomingPhases.first }
}
