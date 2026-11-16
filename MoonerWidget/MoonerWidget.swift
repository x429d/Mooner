import SwiftUI
import WidgetKit

// MARK: - Timeline

struct MoonEntry: TimelineEntry {
    let date: Date
    let snapshot: MoonSnapshot
}

struct MoonProvider: TimelineProvider {
    /// A representative phase makes the widget gallery preview attractive.
    /// Real widgets always switch to the live phase as soon as they load.
    private func previewEntry() -> MoonEntry {
        let date = LunarMath.nextPhase(after: Date(), target: 0.25)
        return MoonEntry(date: date, snapshot: MoonSnapshot(date: date))
    }

    func placeholder(in context: Context) -> MoonEntry {
        previewEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (MoonEntry) -> Void) {
        if context.isPreview {
            completion(previewEntry())
        } else {
            let date = Date()
            completion(MoonEntry(date: date, snapshot: MoonSnapshot(date: date)))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoonEntry>) -> Void) {
        let now = Date()
        let horizon = now.addingTimeInterval(48 * 3_600)

        var dates = Set((0..<48).map { hour in
            now.addingTimeInterval(Double(hour) * 3_600)
        })

        // Add exact principal-phase moments so the age resets and the phase
        // name changes on time, instead of waiting for the next hourly entry.
        let upcoming = MoonSnapshot(date: now).upcomingPhases
        for event in upcoming where event.date > now && event.date < horizon {
            dates.insert(event.date)
            // One minute later makes sure the trend arrow and age have
            // crossed the event even if the event estimate lands a hair early.
            dates.insert(event.date.addingTimeInterval(60))
        }

        let entries: [MoonEntry] = dates.sorted().map { date in
            MoonEntry(date: date, snapshot: MoonSnapshot(date: date))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Widget

struct MoonWidget: Widget {
    private let kind = "MoonerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoonProvider()) { entry in
            MoonWidgetView(entry: entry)
        }
        .configurationDisplayName("Moon")
        .description("The current moon phase, its illumination, and the next lunar milestones.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct MoonWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    let entry: MoonEntry

    private var widgetSize: MoonWidgetSize {
        switch family {
        case .systemSmall: return .small
        case .systemMedium: return .medium
        case .systemLarge: return .large
        default: return .small
        }
    }

    private var renderStyle: MoonRenderStyle {
        renderingMode == .fullColor ? .fullColor : .accented
    }

    var body: some View {
        MoonWidgetContent(
            snapshot: entry.snapshot,
            size: widgetSize,
            style: renderStyle,
            systemAccent: renderStyle == .accented
        )
        .containerBackground(for: .widget) {
            if renderStyle == .fullColor {
                MoonBackground(size: widgetSize)
            } else {
                Color.clear
            }
        }
        .overlay {
            // In clear/tinted mode macOS draws the glass container edge
            // itself; an extra ring here would read as a double border.
            if renderStyle == .fullColor {
                ContainerRelativeShape()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.24),
                                .white.opacity(0.07)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
    }
}

@main
struct MoonerWidgetBundle: WidgetBundle {
    var body: some Widget {
        MoonWidget()
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    MoonWidget()
} timeline: {
    MoonEntry(date: Date(), snapshot: MoonSnapshot(date: Date()))
}

#Preview(as: .systemMedium) {
    MoonWidget()
} timeline: {
    MoonEntry(date: Date(), snapshot: MoonSnapshot(date: Date()))
}

#Preview(as: .systemLarge) {
    MoonWidget()
} timeline: {
    MoonEntry(date: Date(), snapshot: MoonSnapshot(date: Date()))
}
