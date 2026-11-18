import Foundation
import Testing
@testable import Mooner

// MARK: - Golden ephemeris moments

/// Fixed reference moments published for 2026 (timeanddate.com, in UTC, and
/// Astronomy magazine, Eastern converted to UTC). Meeus' truncated series
/// keep the error within a few minutes of these, so the tolerance below is
/// generous on purpose: it catches formula regressions without being flaky.
@Suite("Golden ephemeris moments")
struct AstronomyGoldenTests {
    private static let tolerance: TimeInterval = 10 * 60

    @Test("principal phase moments in 2026 match published ephemerides")
    func principalPhases2026() {
        let cases: [(start: Date, target: Double, expected: Date, label: String)] = [
            (utcDate(2026, 1, 20), 0.5, utcDate(2026, 2, 1, 22, 9), "full moon Feb 1"),
            (utcDate(2026, 5, 10), 0, utcDate(2026, 5, 16, 20, 1), "new moon May 16"),
            (utcDate(2026, 5, 18), 0.25, utcDate(2026, 5, 23, 11, 10), "first quarter May 23"),
            (utcDate(2026, 5, 24), 0.5, utcDate(2026, 5, 31, 8, 45), "blue moon May 31"),
            (utcDate(2026, 11, 10), 0.25, utcDate(2026, 11, 17, 11, 47), "first quarter Nov 17"),
            (utcDate(2026, 11, 18), 0.5, utcDate(2026, 11, 24, 14, 53), "beaver moon Nov 24")
        ]

        for testCase in cases {
            let computed = LunarMath.nextPhase(after: testCase.start, target: testCase.target)
            #expect(
                abs(computed.timeIntervalSince(testCase.expected)) <= Self.tolerance,
                "\(testCase.label): computed \(computed), expected \(testCase.expected)"
            )
        }
    }

    @Test("the latest new moon before Nov 12, 2026 is the Nov 9 new moon")
    func previousNewMoon() {
        let computed = LunarMath.previousNewMoon(before: utcDate(2026, 11, 12))
        #expect(abs(computed.timeIntervalSince(utcDate(2026, 11, 9, 7, 2))) <= Self.tolerance)
    }

    @Test("illumination at the exact principal moments")
    func illuminationAtEvents() {
        // At the elongation crossing the illuminated fraction is
        // mathematically exact: half at quarters, ~whole at full, ~dark at new.
        let firstQuarter = LunarMath.illuminatedFraction(at: utcDate(2026, 11, 17, 11, 47))
        #expect(abs(firstQuarter - 0.5) < 0.01)

        let full = LunarMath.illuminatedFraction(at: utcDate(2026, 11, 24, 14, 53))
        #expect(full > 0.995)

        // The Moon's ecliptic latitude bounds the residual at new moon.
        let new = LunarMath.illuminatedFraction(at: utcDate(2026, 5, 16, 20, 1))
        #expect(new < 0.005)
    }
}

// MARK: - Invariants across a century

@Suite("Astronomy invariants")
struct AstronomyPropertyTests {
    /// Deterministic seeded samples (1970–2070) so any failure reproduces.
    private static func sampleDates(count: Int) -> [Date] {
        var seed: UInt64 = 0x9E37_79B9_7F4A_7C15
        func next() -> UInt64 {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return seed >> 11
        }
        return (0..<count).map { _ in
            Date(timeIntervalSince1970: Double(next() % 3_153_600_000))
        }
    }

    @Test("phase and illumination stay in range across a century")
    func ranges() {
        for date in Self.sampleDates(count: 200) {
            let phase = LunarMath.phaseFraction(at: date)
            #expect(phase >= 0 && phase < 1)

            let illumination = LunarMath.illuminatedFraction(at: date)
            #expect(illumination >= 0 && illumination <= 1)
        }
    }

    @Test("snapshots stay internally consistent")
    func snapshotConsistency() {
        for date in Self.sampleDates(count: 50) {
            let snapshot = MoonSnapshot(date: date)

            #expect(snapshot.previousNewMoon <= date)
            #expect(snapshot.age >= 0 && snapshot.age < 30)
            #expect(snapshot.upcomingPhases.count == 4)
            #expect(
                snapshot.upcomingPhases.map(\.date)
                    == snapshot.upcomingPhases.map(\.date).sorted()
            )

            let kinds = Set(snapshot.upcomingPhases.map(\.kind))
            #expect(kinds == [.newMoon, .firstQuarter, .fullMoon, .lastQuarter])

            for event in snapshot.upcomingPhases {
                #expect(event.date > date)
                #expect(event.date < date.addingTimeInterval(40 * 86_400))
            }

            // The cycle position repeats roughly every synodic month.
            let monthLater = LunarMath.phaseFraction(
                at: date.addingTimeInterval(29.530588853 * 86_400)
            )
            #expect(abs(monthLater - snapshot.phaseFraction) < 0.05)
        }
    }
}

// MARK: - Phase names

@Suite("Phase names")
struct MoonPhaseNameTests {
    @Test("current(for:) boundaries")
    func boundaries() {
        let expectations: [(fraction: Double, name: MoonPhaseName)] = [
            (0.0, .newMoon), (0.009, .newMoon), (0.99, .newMoon), (0.995, .newMoon),
            (0.01, .waxingCrescent), (0.239, .waxingCrescent), (0.985, .waningCrescent),
            (0.24, .firstQuarter), (0.25, .firstQuarter), (0.259, .firstQuarter),
            (0.26, .waxingGibbous), (0.489, .waxingGibbous),
            (0.49, .fullMoon), (0.5, .fullMoon), (0.509, .fullMoon),
            (0.51, .waningGibbous), (0.739, .waningGibbous),
            (0.74, .lastQuarter), (0.75, .lastQuarter), (0.759, .lastQuarter),
            (0.76, .waningCrescent)
        ]

        for expectation in expectations {
            #expect(
                MoonPhaseName.current(for: expectation.fraction) == expectation.name,
                "fraction \(expectation.fraction)"
            )
        }
    }

    @Test("fractions outside 0..<1 wrap into the cycle")
    func wraps() {
        #expect(MoonPhaseName.current(for: 1.25) == .firstQuarter)
        #expect(MoonPhaseName.current(for: -0.01) == .newMoon)
        #expect(MoonPhaseName.current(for: 1.985) == .waningCrescent)
    }
}
