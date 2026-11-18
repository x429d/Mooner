import Combine
import SwiftUI
import WidgetKit

// MARK: - Preview phase

private enum PreviewPhase: String, CaseIterable, Identifiable {
    case now
    case newMoon
    case firstQuarter
    case fullMoon
    case lastQuarter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .now: return "Now"
        case .newMoon: return "New"
        case .firstQuarter: return "First quarter"
        case .fullMoon: return "Full"
        case .lastQuarter: return "Last quarter"
        }
    }

    var target: Double? {
        switch self {
        case .now: return nil
        case .newMoon: return 0
        case .firstQuarter: return 0.25
        case .fullMoon: return 0.5
        case .lastQuarter: return 0.75
        }
    }
}

// MARK: - Preview style

/// What the showcase previews: the color widget, the studio glass material,
/// or the monochrome dimmed appearance macOS uses on the desktop.
private enum PreviewStyle: String, CaseIterable, Identifiable {
    case color
    case glass
    case dimmed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .color: return "Color"
        case .glass: return "Glass"
        case .dimmed: return "Dimmed"
        }
    }

    var renderStyle: MoonRenderStyle {
        self == .color ? .fullColor : .accented
    }
}

// MARK: - Content

struct ContentView: View {
    @State private var selectedPhase: PreviewPhase
    @State private var previewStyle: PreviewStyle
    @State private var snapshot: MoonSnapshot
    @State private var didReload = false

    /// Approximates the desktop's dimmed clear/tinted widget appearance —
    /// monochrome content on system glass. Also via `--preview-dimmed`.
    private var dimmedSimulation: Bool { previewStyle == .dimmed }

    private let clock = Timer.publish(every: 300, on: .main, in: .common).autoconnect()

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let phaseArgument = arguments
            .first { $0.hasPrefix("--preview-phase=") }
            .map { String($0.dropFirst("--preview-phase=".count)) }

        let phase: PreviewPhase
        switch phaseArgument {
        case "newMoon": phase = .newMoon
        case "firstQuarter": phase = .firstQuarter
        case "fullMoon": phase = .fullMoon
        case "lastQuarter": phase = .lastQuarter
        default: phase = .now
        }

        let styleArgument = arguments
            .first { $0.hasPrefix("--preview-style=") }
            .map { String($0.dropFirst("--preview-style=".count)) }

        let style: PreviewStyle
        if arguments.contains("--preview-dimmed") || styleArgument == "dimmed" {
            style = .dimmed
        } else if styleArgument == "color" {
            style = .color
        } else {
            style = .glass
        }

        let date: Date
        if let target = phase.target {
            date = LunarMath.nextPhase(after: Date(), target: target)
                .addingTimeInterval(60)
        } else {
            date = Date()
        }

        _selectedPhase = State(initialValue: phase)
        _previewStyle = State(initialValue: style)
        _snapshot = State(initialValue: MoonSnapshot(date: date))
    }

    var body: some View {
        ZStack {
            DesktopBackdrop()

            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 40)

                Color.clear.frame(height: 16)

                phasePicker
                    .padding(.horizontal, 40)

                Color.clear.frame(height: 14)

                previewRow

                Spacer(minLength: 16)

                footer
                    .padding(.horizontal, 40)
            }
            .padding(.top, 44)
            .padding(.bottom, 24)
        }
        .frame(width: 1_024, height: 736)
        .preferredColorScheme(.dark)
        .onReceive(clock) { _ in
            guard selectedPhase == .now else { return }
            snapshot = MoonSnapshot(date: Date())
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 15) {
            MoonPhaseView(phase: snapshot.phaseFraction, size: 52, style: .fullColor)
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 3) {
                Text("Mooner")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .tracking(-0.6)

                Text("A live moon phase for your Mac desktop.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.52))
            }

            Spacer(minLength: 16)

            statusPill
        }
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(selectedPhase == .now
                    ? Color(red: 0.45, green: 0.90, blue: 0.62)
                    : Color(red: 0.96, green: 0.73, blue: 0.40)
                )
                .frame(width: 6, height: 6)
                .shadow(
                    color: (selectedPhase == .now
                        ? Color(red: 0.45, green: 0.90, blue: 0.62)
                        : Color(red: 0.96, green: 0.73, blue: 0.40)
                    ).opacity(0.8),
                    radius: 4
                )

            Text(statusText)
                .font(.system(size: 11.5, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.65))
                .lineLimit(1)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 7)
        .background(Capsule().fill(.white.opacity(0.055)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.08), lineWidth: 1))
    }

    private var statusText: String {
        let phase = "\(snapshot.name.title) · \(snapshot.illuminationPercent)%"
        if selectedPhase == .now { return "Live · \(phase)" }
        return "Preview · \(MoonFormat.dayMonth(snapshot.date)) · \(phase)"
    }

    // MARK: Phase picker

    private var phasePicker: some View {
        HStack(spacing: 8) {
            Text("Preview a phase")
                .font(.system(size: 9.5, weight: .semibold))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.32))
                .padding(.trailing, 3)

            ForEach(PreviewPhase.allCases) { phase in
                phaseChip(phase)
            }

            Spacer(minLength: 8)

            HStack(spacing: 5) {
                Text("Style")
                    .font(.system(size: 9.5, weight: .semibold))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.32))
                    .padding(.trailing, 2)

                ForEach(PreviewStyle.allCases) { style in
                    styleChip(style)
                }
            }
        }
    }

    private func styleChip(_ style: PreviewStyle) -> some View {
        let isSelected = previewStyle == style

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                previewStyle = style
            }
        } label: {
            Text(style.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isSelected ? Color(red: 0.06, green: 0.07, blue: 0.12) : .white.opacity(0.58))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white.opacity(0.84) : Color.white.opacity(0.045))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(.white.opacity(isSelected ? 0 : 0.07), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .help(helpText(for: style))
        .accessibilityLabel("Preview \(style.title.lowercased()) style")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func helpText(for style: PreviewStyle) -> String {
        switch style {
        case .color: return "Preview the deep-space color widget."
        case .glass: return "Preview the cool cosmic glass material."
        case .dimmed: return "Preview the monochrome dimmed widget macOS shows on the desktop."
        }
    }

    private func phaseChip(_ phase: PreviewPhase) -> some View {
        let isSelected = selectedPhase == phase

        return Button {
            select(phase)
        } label: {
            HStack(spacing: 7) {
                if let target = phase.target {
                    MoonPhaseView(
                        phase: target,
                        size: 16,
                        style: .fullColor,
                        isMini: true,
                        earthshineOpacity: 0.24
                    )
                } else {
                    Circle()
                        .fill(Color(red: 0.45, green: 0.90, blue: 0.62))
                        .frame(width: 5, height: 5)
                        .shadow(color: Color(red: 0.45, green: 0.90, blue: 0.62).opacity(0.8), radius: 3)
                        .frame(width: 16, height: 16)
                }

                Text(phase.title)
                    .font(.system(size: 11.5, weight: .medium))
            }
            .foregroundStyle(isSelected ? Color(red: 0.06, green: 0.07, blue: 0.12) : .white.opacity(0.67))
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? Color.white.opacity(0.90) : Color.white.opacity(0.055))
            )
            .overlay(
                Capsule()
                    .strokeBorder(.white.opacity(isSelected ? 0 : 0.075), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .accessibilityLabel("Preview \(phase.title)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func select(_ phase: PreviewPhase) {
        withAnimation(.easeInOut(duration: 0.18)) {
            selectedPhase = phase
            if let target = phase.target {
                // A minute after the exact event keeps the preview on the
                // outgoing side of the cycle (waxing after new/first quarter,
                // waning after full/last quarter) rather than a hair before it.
                let phaseDate = LunarMath.nextPhase(after: Date(), target: target)
                snapshot = MoonSnapshot(date: phaseDate.addingTimeInterval(60))
            } else {
                snapshot = MoonSnapshot(date: Date())
            }
        }
    }

    // MARK: Widget previews

    private var previewRow: some View {
        HStack(alignment: .center, spacing: 22) {
            previewCard(size: .small, width: 158, height: 158, caption: "Small")
            previewCard(size: .medium, width: 338, height: 158, caption: "Medium")
            previewCard(size: .large, width: 338, height: 338, caption: "Large")
        }
        .frame(maxWidth: .infinity)
    }

    private func previewCard(
        size: MoonWidgetSize,
        width: CGFloat,
        height: CGFloat,
        caption: String
    ) -> some View {
        VStack(spacing: 11) {
            ZStack {
                if previewStyle == .color {
                    MoonBackground(size: size)
                } else {
                    MoonGlassMaterial()
                }

                MoonWidgetContent(
                    snapshot: snapshot,
                    size: size,
                    style: previewStyle.renderStyle,
                    systemAccent: dimmedSimulation
                )
            }
            .saturation(dimmedSimulation ? 0 : 1)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                if !dimmedSimulation {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.28),
                                    .white.opacity(0.07)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            }
            .shadow(color: .black.opacity(0.45), radius: 26, x: 0, y: 15)
            .shadow(color: .black.opacity(0.20), radius: 5, x: 0, y: 2)
            .shadow(
                color: size == .large && !dimmedSimulation
                    ? Color(red: 0.32, green: 0.48, blue: 0.90).opacity(0.22)
                    : .clear,
                radius: 50,
                x: 0,
                y: 10
            )

            Text(caption)
                .font(.system(size: 9.5, weight: .semibold))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.28))
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack(alignment: .center, spacing: 28) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Put Mooner on your desktop")
                    .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                    .padding(.bottom, 2)

                step(1, "Right-click the desktop, then choose Edit Widgets…")
                step(2, "Search for Mooner and pick Small, Medium, or Large.")
                step(3, "That’s it — the widget follows the real lunar cycle.")

                Text("No location, account, or internet connection required.")
                    .font(.system(size: 10.5, weight: .regular))
                    .foregroundStyle(.white.opacity(0.28))
                    .padding(.top, 3)
                    .padding(.leading, 24)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 9) {
                Button {
                    WidgetCenter.shared.reloadAllTimelines()
                    didReload = true
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(1.8))
                        didReload = false
                    }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: didReload ? "checkmark" : "arrow.clockwise")
                            .font(.system(size: 10.5, weight: .semibold))
                        Text(didReload ? "Widgets reloaded" : "Reload widgets")
                            .font(.system(size: 11.5, weight: .semibold))
                    }
                    .foregroundStyle(Color(red: 0.07, green: 0.08, blue: 0.12))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(.white.opacity(0.91)))
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
                .accessibilityLabel("Reload widgets")

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit Mooner")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.42))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(.white.opacity(0.05)))
                        .overlay(Capsule().strokeBorder(.white.opacity(0.07), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
                .accessibilityLabel("Quit Mooner")
            }
        }
        .padding(.horizontal, 21)
        .padding(.vertical, 17)
        .background {
            MoonGlassMaterial()
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.16),
                            .white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Text("\(number)")
                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.46))
                .frame(width: 15, height: 15)
                .background(Circle().fill(.white.opacity(0.075)))

            Text(text)
                .font(.system(size: 11.5, weight: .regular))
                .foregroundStyle(.white.opacity(0.58))
        }
    }
}

// MARK: - Desktop backdrop

private struct DesktopBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0x111A36),
                    Color(hex: 0x0C1222),
                    Color(hex: 0x080B13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color(red: 0.22, green: 0.35, blue: 0.76).opacity(0.60),
                    Color(red: 0.16, green: 0.24, blue: 0.55).opacity(0.22),
                    .clear
                ],
                center: UnitPoint(x: 0.04, y: 0.0),
                startRadius: 0,
                endRadius: 860
            )

            RadialGradient(
                colors: [
                    Color(red: 0.28, green: 0.42, blue: 0.80).opacity(0.18),
                    .clear
                ],
                center: UnitPoint(x: 0.82, y: 0.24),
                startRadius: 0,
                endRadius: 620
            )

            RadialGradient(
                colors: [
                    Color(red: 0.14, green: 0.21, blue: 0.44).opacity(0.12),
                    .clear
                ],
                center: UnitPoint(x: 0.42, y: 0.46),
                startRadius: 0,
                endRadius: 700
            )

            StarField()
                .opacity(0.42)

            LinearGradient(
                colors: [Color.white.opacity(0.03), .clear],
                startPoint: .top,
                endPoint: .center
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - App

@main
struct MoonerApp: App {
    init() {
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                LiveAppIcon.start()
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1_024, height: 736)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
