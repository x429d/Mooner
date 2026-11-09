import SwiftUI

// MARK: - Sizes and styles

enum MoonWidgetSize {
    case small
    case medium
    case large
}

/// System-rendered glass widgets are desaturated by macOS. The moon keeps its
/// texture but changes its glow temperature so it belongs to the material.
enum MoonRenderStyle {
    case fullColor
    case accented
}

// MARK: - Phase shape

/// The lit or shadowed lune of the Moon for a given 0...1 phase.
///
/// The path is a limb semicircle plus a half-ellipse terminator. Drawing it
/// with sampled points keeps the geometry exact and avoids arc-direction
/// surprises across SwiftUI versions.
struct MoonPhaseShape: Shape {
    var phase: Double
    var lit: Bool

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let normalizedPhase = phase - floor(phase)
        let isWaning = normalizedPhase > 0.5
        let waxingPhase = isWaning ? 1 - normalizedPhase : normalizedPhase
        let terminatorX = radius * CGFloat(cos(2 * Double.pi * waxingPhase))

        let top = CGPoint(x: center.x, y: center.y - radius)

        var path = Path()
        path.move(to: top)

        let steps = 120
        let limbStart = -Double.pi / 2
        let limbEnd = Double.pi / 2
        let limbDirection: Double = lit ? 1 : -1

        // Limb semicircle: right side for the lit shape, left for the shadow.
        for index in 1...steps {
            let angle = limbStart + limbDirection * (limbEnd - limbStart) * Double(index) / Double(steps)
            path.addLine(to: CGPoint(
                x: center.x + radius * CGFloat(cos(angle)),
                y: center.y + radius * CGFloat(sin(angle))
            ))
        }

        // Terminator half-ellipse, from bottom back to top.
        for index in 1...steps {
            let angle = limbEnd - (limbEnd - limbStart) * Double(index) / Double(steps)
            path.addLine(to: CGPoint(
                x: center.x + terminatorX * CGFloat(cos(angle)),
                y: center.y + radius * CGFloat(sin(angle))
            ))
        }

        path.closeSubpath()

        if isWaning {
            let mirror = CGAffineTransform(
                a: -1, b: 0, c: 0, d: 1,
                tx: rect.minX + rect.maxX, ty: 0
            )
            path = path.applying(mirror)
        }

        return path
    }
}

// MARK: - Full-color background

struct MoonBackground: View {
    let size: MoonWidgetSize

    var body: some View {
        GeometryReader { proxy in
            let dimensions = proxy.size
            let longestSide = max(dimensions.width, dimensions.height)

            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: 0x0B0F19),
                        Color(hex: 0x10182A),
                        Color(hex: 0x131B2E)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        Color(red: 0.32, green: 0.44, blue: 0.82).opacity(0.18),
                        .clear
                    ],
                    center: glowCenter,
                    startRadius: 0,
                    endRadius: longestSide * 0.78
                )

                StarField()

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.035),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )

                RadialGradient(
                    colors: [
                        .clear,
                        Color.black.opacity(0.22)
                    ],
                    center: .center,
                    startRadius: longestSide * 0.22,
                    endRadius: longestSide * 0.78
                )
            }
            .frame(width: dimensions.width, height: dimensions.height)
        }
    }

    private var glowCenter: UnitPoint {
        switch size {
        case .small: return UnitPoint(x: 0.50, y: 0.44)
        case .medium: return UnitPoint(x: 0.26, y: 0.50)
        case .large: return UnitPoint(x: 0.50, y: 0.38)
        }
    }
}

// MARK: - Glass material

/// Unified cool cosmic glass used by the app showcase.
struct MoonGlassMaterial: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            Color(red: 0.10, green: 0.15, blue: 0.28)
                .opacity(0.32)

            RadialGradient(
                colors: [
                    Color(red: 0.34, green: 0.47, blue: 0.84).opacity(0.16),
                    .clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 520
            )

            LinearGradient(
                colors: [
                    Color.white.opacity(0.09),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .center
            )
        }
    }
}

/// Materials are not supported inside the widget's background layer, so the
/// native widget gets the same cool palette as a rendered gradient instead.
struct MoonGlassWidgetBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.14, blue: 0.24),
                    Color(red: 0.04, green: 0.06, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Color(red: 0.08, green: 0.11, blue: 0.18)
                .opacity(0.55)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.055),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .center
            )
        }
    }
}

// MARK: - Stars

struct StarField: View {
    private struct Star {
        let x: Double
        let y: Double
        let radius: Double
        let opacity: Double
    }

    private static let stars: [Star] = {
        var seed: UInt64 = 0x9E37_79B9_7F4A_7C15
        func next() -> Double {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double(seed >> 11) / Double(1 << 53)
        }

        return (0..<54).map { _ in
            Star(
                x: next(),
                y: next(),
                radius: 0.35 + next() * 1.25,
                opacity: 0.08 + next() * 0.42
            )
        }
    }()

    var body: some View {
        Canvas { context, size in
            for star in Self.stars {
                let rect = CGRect(
                    x: star.x * size.width,
                    y: star.y * size.height,
                    width: star.radius,
                    height: star.radius
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(.white.opacity(star.opacity))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Color helper

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
