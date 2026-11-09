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

// MARK: - Content

struct ContentView: View {
    @State private var selectedPhase: PreviewPhase = .now
    @State private var previewStyle: MoonRenderStyle = .fullColor
    @State private var snapshot = MoonSnapshot(date: Date())
    @State private var didReload = false

    private let clock = Timer.publish(every: 300, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            DesktopBackdrop()

            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 36)

                Spacer(minLength: 16)

                phasePicker
                    .padding(.horizontal, 36)

                Spacer(minLength: 14)

                previewRow

                Spacer(minLength: 18)

                footer
                    .padding(.horizontal, 36)
            }
            .padding(.top, 44)
            .padding(.bottom, 26)
        }
        .frame(width: 1_020, height: 770)
        .preferredColorScheme(.dark)
        .onReceive(clock) { _ in
            guard selectedPhase == .now else { return }
            snapshot = MoonSnapshot(date: Date())
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 15) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.55, green: 0.55, blue: 1.0).opacity(0.22),
                                .clear
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: 36
                        )
                    )
                    .frame(width: 64, height: 64)

                MoonDisc(phase: 0.32, size: 47, detailed: true, glow: true)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Mooner")
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                    .tracking(-0.7)

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
        let date = snapshot.date.formatted(.dateTime.month(.abbreviated).day())
        return "Preview · \(date) · \(phase)"
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

                styleChip(.fullColor, title: "Color")
                styleChip(.accented, title: "Glass")
            }
        }
    }

    private func styleChip(_ style: MoonRenderStyle, title: String) -> some View {
        let isSelected = previewStyle == style

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                previewStyle = style
            }
        } label: {
            Text(title)
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
        .help(style == .accented
            ? "Preview the monochrome glass look macOS uses when widgets are dimmed."
            : "Preview the full-color widget."
        )
        .accessibilityLabel("Preview \(title.lowercased()) style")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func phaseChip(_ phase: PreviewPhase) -> some View {
        let isSelected = selectedPhase == phase

        return Button {
            select(phase)
        } label: {
            HStack(spacing: 7) {
                if let target = phase.target {
                    MoonDisc(phase: target, size: 15, detailed: false, glow: false)
                } else {
                    Circle()
                        .fill(Color(red: 0.45, green: 0.90, blue: 0.62))
                        .frame(width: 5, height: 5)
                        .shadow(color: Color(red: 0.45, green: 0.90, blue: 0.62).opacity(0.8), radius: 3)
                        .frame(width: 15, height: 15)
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
                snapshot = MoonSnapshot(date: LunarMath.nextPhase(after: Date(), target: target))
            } else {
                snapshot = MoonSnapshot(date: Date())
            }
        }
    }

    // MARK: Widget previews

    private var previewRow: some View {
        HStack(alignment: .top, spacing: 22) {
            previewCard(size: .small, width: 170, height: 170, caption: "Small")
            previewCard(size: .medium, width: 364, height: 170, caption: "Medium")
            previewCard(size: .large, width: 364, height: 382, caption: "Large")
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
            Spacer(minLength: 0)

            ZStack {
                if previewStyle == .fullColor {
                    MoonBackground(size: size)
                } else {
                    GlassPreviewBackground()
                }

                MoonWidgetContent(
                    snapshot: snapshot,
                    displayDate: snapshot.date,
                    size: size,
                    style: previewStyle
                )
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.22),
                                .white.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.5), radius: 26, x: 0, y: 15)
            .shadow(color: .black.opacity(0.24), radius: 5, x: 0, y: 2)

            Text(caption)
                .font(.system(size: 9.5, weight: .semibold))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.28))

            Spacer(minLength: 0)
        }
        .frame(width: max(width, 140), height: 412)
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
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
                .accessibilityLabel("Quit Mooner")
            }
        }
        .padding(.horizontal, 21)
        .padding(.vertical, 17)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white.opacity(0.042))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.10), .white.opacity(0.025)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
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

// MARK: - Glass preview

private struct GlassPreviewBackground: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.10),
                    Color(red: 0.92, green: 0.68, blue: 0.45).opacity(0.10),
                    Color.black.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [Color.white.opacity(0.05), .clear],
                startPoint: .top,
                endPoint: .center
            )
        }
    }
}

// MARK: - Desktop backdrop

private struct DesktopBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.045, green: 0.060, blue: 0.115),
                    Color(red: 0.055, green: 0.064, blue: 0.115),
                    Color(red: 0.105, green: 0.062, blue: 0.060)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color(red: 0.44, green: 0.47, blue: 0.98).opacity(0.29),
                    .clear
                ],
                center: UnitPoint(x: 0.08, y: 0.02),
                startRadius: 0,
                endRadius: 680
            )

            RadialGradient(
                colors: [
                    Color(red: 0.98, green: 0.44, blue: 0.24).opacity(0.20),
                    .clear
                ],
                center: UnitPoint(x: 0.94, y: 0.78),
                startRadius: 0,
                endRadius: 760
            )

            RadialGradient(
                colors: [
                    Color(red: 0.16, green: 0.68, blue: 0.64).opacity(0.10),
                    .clear
                ],
                center: UnitPoint(x: 0.58, y: 1.05),
                startRadius: 0,
                endRadius: 640
            )

            StarField()
                .opacity(0.55)

            LinearGradient(
                colors: [Color.white.opacity(0.045), .clear],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.45)
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - App

@main
struct MoonerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1_020, height: 770)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
