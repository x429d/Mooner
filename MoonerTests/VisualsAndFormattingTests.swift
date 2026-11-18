import Foundation
import SwiftUI
import Testing
@testable import Mooner

// MARK: - Snapshot integration

@Suite("Snapshot")
struct MoonSnapshotTests {
    @Test("snapshot at the first quarter of November 2026")
    func snapshotAtFirstQuarter() {
        let date = utcDate(2026, 11, 17, 11, 47)
        let snapshot = MoonSnapshot(date: date)

        #expect(snapshot.name == .firstQuarter)
        // The previous new moon was Nov 9, 07:02 UTC: 8.2 days earlier.
        #expect(abs(snapshot.age - 8.20) < 0.05)
        #expect(abs(snapshot.illumination - 0.5) < 0.01)
        #expect(snapshot.illuminationPercent == 50)

        // The published moment sits a couple of minutes before the computed
        // elongation crossing, so the next first quarter still counts as
        // "upcoming"; the next *distinct* milestone is the November full moon.
        let fullMoon = snapshot.upcomingPhases.first { $0.kind == .fullMoon }
        #expect(fullMoon != nil)
        #expect(fullMoon?.targetFraction == 0.5)
        #expect(abs(fullMoon!.date.timeIntervalSince(utcDate(2026, 11, 24, 14, 53))) < 10 * 60)

        // Events carry the cycle fraction they represent.
        let fractions = Dictionary(
            uniqueKeysWithValues: snapshot.upcomingPhases.map { ($0.kind, $0.targetFraction) }
        )
        #expect(fractions[.newMoon] == 0)
        #expect(fractions[.firstQuarter] == 0.25)
        #expect(fractions[.fullMoon] == 0.5)
        #expect(fractions[.lastQuarter] == 0.75)
    }

    @Test("a sliver of illumination still reads as at least one percent")
    func sliverIllumination() {
        // At the exact May 2026 new moon the disc is (nearly) dark.
        let snapshot = MoonSnapshot(date: utcDate(2026, 5, 16, 20, 1))
        #expect(snapshot.name == .newMoon)
        #expect(snapshot.illumination < 0.005)
        if snapshot.illumination > 0 {
            #expect(snapshot.illuminationPercent >= 1)
        }
    }
}

// MARK: - Phase shape geometry

@Suite("Phase shape geometry")
struct MoonPhaseShapeTests {
    private let rect = CGRect(x: 0, y: 0, width: 100, height: 100)

    /// Fraction of a grid of sample points inside the lit shape.
    private func litAreaFraction(phase: Double) -> Double {
        let path = MoonPhaseShape(phase: phase, lit: true).path(in: rect)
        let samples = 33
        var inside = 0
        for x in 0..<samples {
            for y in 0..<samples {
                let point = CGPoint(
                    x: (Double(x) + 0.5) / Double(samples) * rect.width,
                    y: (Double(y) + 0.5) / Double(samples) * rect.height
                )
                if path.contains(point) { inside += 1 }
            }
        }
        return Double(inside) / Double(samples * samples)
    }

    @Test("new moon lights nothing, full moon lights the whole disc")
    func extremes() {
        #expect(litAreaFraction(phase: 0) < 0.01, "new moon must have no lit area")
        #expect(litAreaFraction(phase: 1) < 0.01, "phase 1 wraps to new moon")
        #expect(litAreaFraction(phase: 0.999) < 0.01, "nearly-new waning crescent")

        // A full disc covers π/4 ≈ 0.785 of its bounding square.
        #expect(abs(litAreaFraction(phase: 0.5) - 0.785) < 0.04)
    }

    @Test("quarters light exactly half the disc")
    func quarters() {
        let full = litAreaFraction(phase: 0.5)
        #expect(abs(litAreaFraction(phase: 0.25) - full / 2) < 0.02)
        #expect(abs(litAreaFraction(phase: 0.75) - full / 2) < 0.02)
    }

    @Test("waning mirrors waxing")
    func mirroring() {
        let waxing = MoonPhaseShape(phase: 0.25, lit: true).path(in: rect)
        let waning = MoonPhaseShape(phase: 0.75, lit: true).path(in: rect)

        #expect(waxing.contains(CGPoint(x: 75, y: 50)))
        #expect(!waxing.contains(CGPoint(x: 25, y: 50)))
        #expect(waning.contains(CGPoint(x: 25, y: 50)))
        #expect(!waning.contains(CGPoint(x: 75, y: 50)))
    }

    @Test("the shadow lune complements the lit one")
    func shadowComplement() {
        let lit = MoonPhaseShape(phase: 0.25, lit: true).path(in: rect)
        let shadow = MoonPhaseShape(phase: 0.25, lit: false).path(in: rect)

        #expect(!lit.contains(CGPoint(x: 25, y: 50)))
        #expect(shadow.contains(CGPoint(x: 25, y: 50)))
        #expect(!shadow.contains(CGPoint(x: 75, y: 50)))
    }

    @Test("the phase mask pads the sunlit limb past the clip circle so blur only softens the terminator")
    func maskBleedsPastSunlitLimb() {
        let newMoonMask = MoonPhaseMask(phase: 0).path(in: rect)
        #expect(!newMoonMask.contains(CGPoint(x: 75, y: 50)))

        let firstQuarterMask = MoonPhaseMask(phase: 0.25).path(in: rect)
        #expect(firstQuarterMask.contains(CGPoint(x: 105, y: 50)))
        #expect(!firstQuarterMask.contains(CGPoint(x: 25, y: 50)))

        let waningQuarterMask = MoonPhaseMask(phase: 0.75).path(in: rect)
        #expect(waningQuarterMask.contains(CGPoint(x: -5, y: 50)))
        #expect(!waningQuarterMask.contains(CGPoint(x: 75, y: 50)))
    }
}

// MARK: - Formatting

@Suite("Formatting")
struct MoonFormatTests {
    @Test("numbers keep the English decimal point")
    func decimal() {
        #expect(MoonFormat.decimal(8.234) == "8.2")
        #expect(MoonFormat.decimal(29.5306, fractionDigits: 3) == "29.531")
        #expect(MoonFormat.decimal(0.04) == "0.0")
    }

    @Test("day-month in English order, without the year")
    func dayMonth() {
        #expect(MoonFormat.dayMonth(utcDate(2026, 11, 24)) == "24 Nov")
    }

    @Test("countdown buckets")
    func countdown() {
        let now = utcDate(2026, 11, 18, 12)
        #expect(MoonFormat.countdown(now.addingTimeInterval(90 * 60), from: now) == "in 2h")
        #expect(MoonFormat.countdown(now.addingTimeInterval(3 * 86_400), from: now) == "in 3d")
        #expect(MoonFormat.countdown(now.addingTimeInterval(-10), from: now) == "today")
    }

    @Test("full moon phrase singular and plural")
    func fullMoonPhrase() {
        let now = utcDate(2026, 11, 18, 12)
        #expect(MoonFormat.fullMoonPhrase(now, from: now) == "Full moon today")
        #expect(
            MoonFormat.fullMoonPhrase(now.addingTimeInterval(1.2 * 86_400), from: now)
                == "Full moon in 1 day"
        )
        #expect(
            MoonFormat.fullMoonPhrase(now.addingTimeInterval(30 * 86_400), from: now)
                == "Full moon in 30 days"
        )
    }
}
