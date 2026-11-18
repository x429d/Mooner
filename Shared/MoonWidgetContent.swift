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

    private var milestoneText: String {
        if snapshot.name == .fullMoon {
            return "Full today"
        }
        return "Full \(snapshot.fullMoonCountdown)"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(snapshot.trendWord.uppercased()) \(snapshot.trendArrow)")
                    .font(.system(size: 8.5, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.54))

                Spacer(minLength: 4)

                Text("DAY \(snapshot.ageText)")
                    .font(.system(size: 8.5, weight: .semibold))
                    .tracking(0.8)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.54))
            }

            Spacer(minLength: 4)

            MoonPhaseView(
                phase: snapshot.phaseFraction,
                size: 78,
                style: style,
                systemAccent: systemAccent,
                compactGlow: true
            )

            Spacer(minLength: 4)

            VStack(spacing: 2.5) {
                Text(snapshot.name.title)
                    .font(.system(size: 15.5, weight: .bold))
                    .tracking(-0.25)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 4) {
                    Text("\(snapshot.illuminationPercent)%")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.86))

                    Text("·")
                        .foregroundStyle(.white.opacity(0.36))

                    Text(milestoneText)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.58))
                }
                .font(.system(size: 11))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
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
        HStack(spacing: 16) {
            MoonPhaseView(
                phase: snapshot.phaseFraction,
                size: 112,
                style: style,
                systemAccent: systemAccent,
                compactGlow: true
            )

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(snapshot.trendWord.uppercased()) \(snapshot.trendArrow)")
                        .font(.system(size: 8.5, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.54))

                    Spacer(minLength: 6)

                    Text("DAY \(snapshot.ageText)")
                        .font(.system(size: 8.5, weight: .semibold))
                        .tracking(0.8)
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.54))
                }

                Text(snapshot.name.title)
                    .font(.system(size: 21, weight: .bold))
                    .tracking(-0.35)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .padding(.top, 1.5)

                HStack(spacing: 4) {
                    Text("\(snapshot.illuminationPercent)% illuminated")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.84))

                    Text("·")
                        .foregroundStyle(.white.opacity(0.36))

                    Text("Full \(snapshot.fullMoonCountdown)")
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.58))
                }
                .font(.system(size: 11))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.top, 1.5)

                Spacer(minLength: 4)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.16),
                                .white.opacity(0.05)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                Spacer(minLength: 5)

                HStack(spacing: 0) {
                    ForEach(Array(snapshot.upcomingPhases.prefix(3).enumerated()), id: \.element.id) { index, event in
                        if index > 0 {
                            Spacer(minLength: 8)
                        }
                        MediumForecastCell(
                            event: event,
                            isNext: index == 0,
                            style: style,
                            systemAccent: systemAccent
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(snapshot.name.title), \(snapshot.illuminationPercent) percent illuminated, \(snapshot.fullMoonPhrase)"
        )
    }
}

private struct MediumForecastCell: View {
    let event: MoonPhaseEvent
    let isNext: Bool
    let style: MoonRenderStyle
    let systemAccent: Bool

    var body: some View {
        VStack(spacing: 2.5) {
            MoonPhaseView(
                phase: event.targetFraction,
                size: 19,
                style: style,
                isMini: true,
                earthshineOpacity: 0.30,
                systemAccent: systemAccent
            )

            Text(event.kind.forecastTitle)
                .font(.system(size: 8.5, weight: .bold))
                .tracking(0.4)
                .foregroundStyle(.white.opacity(isNext ? 0.94 : 0.80))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(MoonFormat.dayMonth(event.date))
                .font(.system(size: 10, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(isNext ? 0.68 : 0.54))
                .lineLimit(1)
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
                Text("\(snapshot.trendWord.uppercased()) PHASE \(snapshot.trendArrow)")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.85)
                    .foregroundStyle(.white.opacity(0.56))

                Spacer(minLength: 8)

                Text("AGE \(snapshot.ageText) DAYS")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.85)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.56))
            }

            Spacer(minLength: 6)

            MoonPhaseView(
                phase: snapshot.phaseFraction,
                size: 148,
                style: style,
                systemAccent: systemAccent
            )

            Spacer(minLength: 8)

            Text(snapshot.name.title)
                .font(.system(size: 24.5, weight: .bold))
                .tracking(-0.35)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            HStack(spacing: 5) {
                Text("\(snapshot.illuminationPercent)% illuminated")
                    .foregroundStyle(.white.opacity(0.84))

                Text("·")
                    .foregroundStyle(.white.opacity(0.36))

                Text(snapshot.fullMoonPhrase)
                    .foregroundStyle(.white.opacity(0.60))
            }
            .font(.system(size: 12.5, weight: .medium))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.top, 3)

            Spacer(minLength: 9)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.04),
                            .white.opacity(0.16),
                            .white.opacity(0.04)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            HStack(spacing: 0) {
                ForEach(Array(snapshot.upcomingPhases.prefix(4).enumerated()), id: \.element.id) { index, event in
                    ForecastCell(
                        event: event,
                        isNext: index == 0,
                        style: style,
                        systemAccent: systemAccent
                    )
                }
            }
            .padding(.top, 10)
        }
        .padding(16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(snapshot.name.title), \(snapshot.illuminationPercent) percent illuminated, \(snapshot.fullMoonPhrase)"
        )
    }
}

// MARK: - Forecast cell

private struct ForecastCell: View {
    let event: MoonPhaseEvent
    let isNext: Bool
    let style: MoonRenderStyle
    let systemAccent: Bool

    var body: some View {
        VStack(spacing: 4.5) {
            MoonPhaseView(
                phase: event.targetFraction,
                size: 26,
                style: style,
                isMini: true,
                earthshineOpacity: 0.30,
                systemAccent: systemAccent
            )

            Text(event.kind.forecastTitle)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.45)
                .foregroundStyle(.white.opacity(isNext ? 0.95 : 0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(MoonFormat.dayMonth(event.date))
                .font(.system(size: 10.5, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(isNext ? 0.70 : 0.54))
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
