import SwiftUI

// MARK: - Shared widget content

struct MoonWidgetContent: View {
    let snapshot: MoonSnapshot
    let displayDate: Date
    let size: MoonWidgetSize
    var style: MoonRenderStyle = .fullColor

    var body: some View {
        Group {
            switch size {
            case .small:
                SmallMoonWidget(snapshot: snapshot, displayDate: displayDate, style: style)
            case .medium:
                MediumMoonWidget(snapshot: snapshot, displayDate: displayDate, style: style)
            case .large:
                LargeMoonWidget(snapshot: snapshot, displayDate: displayDate, style: style)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Small

private struct SmallMoonWidget: View {
    let snapshot: MoonSnapshot
    let displayDate: Date
    let style: MoonRenderStyle

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let shortestSide = min(width, height)

            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("Moon")
                        .font(.system(size: max(8, height * 0.055), weight: .semibold))
                        .tracking(1.5)
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.54))

                    Spacer(minLength: 4)

                    Text(displayDate, format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: max(7.5, height * 0.047), weight: .medium))
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.45))
                }

                Spacer(minLength: 0)

                MoonDisc(phase: snapshot.phaseFraction, size: shortestSide * 0.455, style: style)
                    .accessibilityHidden(true)

                Spacer(minLength: 0)

                VStack(spacing: 3) {
                    Text(snapshot.name.title)
                        .font(.system(size: height * 0.086, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("\(snapshot.illuminationPercent)% illuminated")
                        .font(.system(size: height * 0.059, weight: .medium))
                        .foregroundStyle(.white.opacity(0.52))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .shadow(color: .black.opacity(0.22), radius: 8, y: 2)
            }
            .padding(shortestSide * 0.082)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(snapshot.name.title), \(snapshot.illuminationPercent) percent illuminated"
        )
    }
}

// MARK: - Medium

private struct MediumMoonWidget: View {
    let snapshot: MoonSnapshot
    let displayDate: Date
    let style: MoonRenderStyle

    private var ageText: String {
        snapshot.age.formatted(.number.precision(.fractionLength(1)))
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let disc = min(height * 0.69, width * 0.335)
            let padding = height * 0.105

            HStack(spacing: 0) {
                MoonDisc(phase: snapshot.phaseFraction, size: disc, style: style)
                    .accessibilityHidden(true)

                Spacer(minLength: width * 0.038)

                VStack(alignment: .leading, spacing: 0) {
                    Text(snapshot.name.title)
                        .font(.system(size: height * 0.062, weight: .semibold))
                        .tracking(1.25)
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.54))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(snapshot.illuminationPercent)%")
                            .font(.system(size: height * 0.255, weight: .bold, design: .rounded))
                            .tracking(-1)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Text("illuminated")
                            .font(.system(size: height * 0.060, weight: .medium))
                            .foregroundStyle(.white.opacity(0.45))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .padding(.top, 1)

                    Spacer(minLength: 4)

                    Rectangle()
                        .fill(.white.opacity(0.11))
                        .frame(height: 1)

                    HStack(alignment: .top, spacing: 10) {
                        MoonStat(label: "Moon age", value: "\(ageText) days")
                            .layoutPriority(0)

                        Spacer(minLength: 6)

                        if let next = snapshot.nextPhase {
                            MoonStat(
                                label: next.kind.title,
                                value: next.date.formatted(
                                    .dateTime.month(.abbreviated).day()
                                )
                            )
                            .layoutPriority(1)
                        }
                    }
                    .padding(.top, 8)
                }
                .frame(maxHeight: .infinity)
                .padding(.vertical, height * 0.012)
            }
            .padding(.horizontal, padding)
            .padding(.vertical, padding * 0.82)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(snapshot.name.title), \(snapshot.illuminationPercent) percent illuminated, \(ageText) days old"
        )
    }
}

// MARK: - Large

private struct LargeMoonWidget: View {
    let snapshot: MoonSnapshot
    let displayDate: Date
    let style: MoonRenderStyle

    private var ageText: String {
        snapshot.age.formatted(.number.precision(.fractionLength(1)))
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let disc = min(width * 0.47, height * 0.435)
            let padding: CGFloat = 21

            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("The Moon")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.5)
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.50))

                    Spacer(minLength: 8)

                    Text(displayDate, format: .dateTime.month(.wide).day())
                        .font(.system(size: 9.5, weight: .medium))
                        .tracking(0.7)
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.50))
                }

                Spacer(minLength: 5)

                MoonDisc(phase: snapshot.phaseFraction, size: disc, style: style)
                    .accessibilityHidden(true)

                Spacer(minLength: 6)

                Text(snapshot.name.title)
                    .font(.system(size: width * 0.073, weight: .semibold, design: .rounded))
                    .tracking(-0.4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 7) {
                    Text("\(snapshot.illuminationPercent)% illuminated")

                    Circle()
                        .fill(.white.opacity(0.30))
                        .frame(width: 2.5, height: 2.5)

                    Text("Age \(ageText) days")
                }
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.top, 4)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

                Spacer(minLength: 9)

                Rectangle()
                    .fill(.white.opacity(0.10))
                    .frame(height: 1)

                HStack(spacing: 0) {
                    ForEach(snapshot.upcomingPhases) { event in
                        UpcomingPhaseCell(event: event, style: style)
                    }
                }
                .padding(.top, 12)
            }
            .padding(padding)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(snapshot.name.title), \(snapshot.illuminationPercent) percent illuminated, \(ageText) days old"
        )
    }
}

// MARK: - Pieces

private struct MoonStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 8.2, weight: .semibold))
                .tracking(0.9)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.50))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(value)
                .font(.system(size: 12.3, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }
}

private struct UpcomingPhaseCell: View {
    let event: MoonPhaseEvent
    let style: MoonRenderStyle

    var body: some View {
        VStack(spacing: 6) {
            MoonDisc(
                phase: event.kind.targetFraction,
                size: 31,
                detailed: false,
                glow: false,
                style: style
            )
            .accessibilityHidden(true)

            Text(event.kind.shortTitle)
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.55)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.74))
                .lineLimit(1)
                .minimumScaleFactor(0.66)

            Text(event.date, format: .dateTime.month(.abbreviated).day())
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.50))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}
