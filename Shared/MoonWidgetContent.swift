import SwiftUI

// MARK: - Shared widget content

struct MoonWidgetContent: View {
    let snapshot: MoonSnapshot
    let size: MoonWidgetSize
    var style: MoonRenderStyle = .fullColor
    var systemAccent: Bool = false

    var body: some View {
        Group {
            switch size {
            case .small:
                SmallMoonWidget(snapshot: snapshot, style: style, systemAccent: systemAccent)
            case .medium:
                MediumMoonWidget(snapshot: snapshot, style: style, systemAccent: systemAccent)
            case .large:
                LargeMoonWidget(snapshot: snapshot, style: style, systemAccent: systemAccent)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Small

private struct SmallMoonWidget: View {
    let snapshot: MoonSnapshot
    let style: MoonRenderStyle
    let systemAccent: Bool

    var body: some View {
        VStack(spacing: 10) {
            MoonPhaseView(
                phase: snapshot.phaseFraction,
                size: 84,
                style: style,
                systemAccent: systemAccent
            )

            VStack(spacing: 3) {
                Text(snapshot.name.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("\(snapshot.illuminationPercent)% · \(snapshot.trendWord) \(snapshot.trendArrow)")
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(snapshot.name.title), \(snapshot.illuminationPercent) percent illuminated, \(snapshot.trendWord)"
        )
    }
}

// MARK: - Medium

private struct MediumMoonWidget: View {
    let snapshot: MoonSnapshot
    let style: MoonRenderStyle
    let systemAccent: Bool

    var body: some View {
        HStack(spacing: 18) {
            MoonPhaseView(
                phase: snapshot.phaseFraction,
                size: 116,
                style: style,
                systemAccent: systemAccent
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("\(snapshot.trendWord.uppercased()) · DAY \(snapshot.ageText)")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)

                Text(snapshot.name.title)
                    .font(.system(size: 22, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 4)

                Rectangle()
                    .fill(.white.opacity(0.1))
                    .frame(height: 1)
                    .padding(.vertical, 4)

                HStack(alignment: .top, spacing: 12) {
                    metric(title: "Illumination", value: "\(snapshot.illuminationPercent)%")
                        .layoutPriority(0)

                    metric(title: "Full Moon", value: snapshot.fullMoonCountdownAndDate)
                        .layoutPriority(1)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(snapshot.name.title), \(snapshot.illuminationPercent) percent illuminated, \(snapshot.fullMoonPhrase)"
        )
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.4)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }
}

// MARK: - Large

private struct LargeMoonWidget: View {
    let snapshot: MoonSnapshot
    let style: MoonRenderStyle
    let systemAccent: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(snapshot.trendWord.uppercased()) PHASE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.55))

                Spacer(minLength: 8)

                Text("AGE \(snapshot.ageText) DAYS")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer(minLength: 6)

            MoonPhaseView(
                phase: snapshot.phaseFraction,
                size: 142,
                style: style,
                systemAccent: systemAccent
            )

            Spacer(minLength: 8)

            Text(snapshot.name.title)
                .font(.system(size: 22, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text("\(snapshot.illuminationPercent)% illuminated · \(snapshot.fullMoonPhrase)")
                .font(.system(size: 12.5, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.65))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.top, 4)

            Spacer(minLength: 10)

            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(height: 1)

            HStack(spacing: 0) {
                ForEach(Array(snapshot.forecastPhases.prefix(3))) { event in
                    ForecastCell(event: event, style: style, systemAccent: systemAccent)
                }
            }
            .padding(.top, 10)
        }
        .padding(18)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(snapshot.name.title), \(snapshot.illuminationPercent) percent illuminated, \(snapshot.fullMoonPhrase)"
        )
    }
}

// MARK: - Forecast cell

private struct ForecastCell: View {
    let event: MoonPhaseEvent
    let style: MoonRenderStyle
    let systemAccent: Bool

    var body: some View {
        VStack(spacing: 5) {
            MoonPhaseView(
                phase: event.kind.targetFraction,
                size: 28,
                style: style,
                isMini: true,
                earthshineOpacity: 0.24,
                systemAccent: systemAccent
            )

            Text(event.kind.forecastTitle)
                .font(.system(size: 9.5, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(MoonFormat.dayMonth(event.date))
                .font(.system(size: 11, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

private extension MoonPhaseName {
    var forecastTitle: String {
        switch self {
        case .newMoon: return "NEW"
        case .firstQuarter: return "FIRST QTR"
        case .fullMoon: return "FULL"
        case .lastQuarter: return "LAST QTR"
        default: return title.uppercased()
        }
    }
}
