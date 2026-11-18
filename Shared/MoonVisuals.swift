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
                        Color(hex: 0x060913),
                        Color(hex: 0x0B1225),
                        Color(hex: 0x111C35)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Deep sapphire atmospheric scatter behind the lunar sphere
                RadialGradient(
                    colors: [
                        Color(red: 0.28, green: 0.44, blue: 0.88).opacity(0.24),
                        Color(red: 0.18, green: 0.30, blue: 0.66).opacity(0.10),
                        .clear
                    ],
                    center: glowCenter,
                    startRadius: 0,
                    endRadius: longestSide * 0.76
                )

                // Warm selenian core glow around the Moon
                RadialGradient(
                    colors: [
                        Color(red: 0.98, green: 0.92, blue: 0.80).opacity(0.065),
                        .clear
                    ],
                    center: glowCenter,
                    startRadius: 0,
                    endRadius: longestSide * 0.42
                )

                // Subtle horizon depth at bottom-trailing
                RadialGradient(
                    colors: [
                        Color(red: 0.20, green: 0.32, blue: 0.68).opacity(0.12),
                        .clear
                    ],
                    center: UnitPoint(x: 0.88, y: 0.92),
                    startRadius: 0,
                    endRadius: longestSide * 0.65
                )

                StarField()
                    .mask(starFieldMask)

                // Subtle corner vignette for optical depth
                RadialGradient(
                    colors: [
                        .clear,
                        Color.black.opacity(0.24)
                    ],
                    center: .center,
                    startRadius: longestSide * 0.34,
                    endRadius: longestSide * 0.82
                )

                // Top specular glass sheen
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.045),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.42)
                )
            }
            .frame(width: dimensions.width, height: dimensions.height)
        }
    }

    private var glowCenter: UnitPoint {
        switch size {
        case .small: return UnitPoint(x: 0.50, y: 0.44)
        case .medium: return UnitPoint(x: 0.23, y: 0.50)
        case .large: return UnitPoint(x: 0.50, y: 0.36)
        }
    }

    /// Attenuates stars in the typography zones so a bright star never
    /// collides with a letter or middle dot.
    @ViewBuilder
    private var starFieldMask: some View {
        switch size {
        case .small:
            LinearGradient(
                stops: [
                    .init(color: .white, location: 0.0),
                    .init(color: .white.opacity(0.85), location: 0.62),
                    .init(color: .white.opacity(0.18), location: 0.82),
                    .init(color: .white.opacity(0.08), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .medium:
            LinearGradient(
                stops: [
                    .init(color: .white, location: 0.0),
                    .init(color: .white.opacity(0.90), location: 0.42),
                    .init(color: .white.opacity(0.22), location: 0.65),
                    .init(color: .white.opacity(0.15), location: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .large:
            LinearGradient(
                stops: [
                    .init(color: .white, location: 0.0),
                    .init(color: .white.opacity(0.92), location: 0.52),
                    .init(color: .white.opacity(0.20), location: 0.74),
                    .init(color: .white.opacity(0.12), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
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

            Color(red: 0.11, green: 0.15, blue: 0.24)
                .opacity(0.26)

            Color.white.opacity(0.045)

            RadialGradient(
                colors: [
                    Color(red: 0.36, green: 0.50, blue: 0.88).opacity(0.15),
                    .clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 520
            )

            LinearGradient(
                colors: [
                    Color.white.opacity(0.11),
                    Color.white.opacity(0.02),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Stars

struct StarField: View {
    /// Star radii are tuned for widget sizes; large canvases (app icon)
    /// scale them up so they stay visible.
    var scale: CGFloat = 1

    private struct Star {
        let x: Double
        let y: Double
        let radius: Double
        let opacity: Double
        let tint: Color
    }

    private static let stars: [Star] = {
        var seed: UInt64 = 0x9E37_79B9_7F4A_7C15
        func next() -> Double {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double(seed >> 11) / Double(1 << 53)
        }

        let palette: [Color] = [
            Color(red: 1.00, green: 0.96, blue: 0.88), // Warm ivory star
            Color.white,                               // Pure starlight
            Color(red: 0.82, green: 0.90, blue: 1.00)  // Cool blue-white star
        ]

        return (0..<62).map { _ in
            let x = next()
            let y = next()
            let sizeRoll = next()
            let opacityRoll = next()
            let tintIndex = Int(next() * Double(palette.count)) % palette.count

            // Crisp pinpoint distribution without blurry halos
            let radius = 0.35 + pow(sizeRoll, 1.65) * 1.15
            let opacity = 0.08 + opacityRoll * 0.38

            return Star(
                x: x,
                y: y,
                radius: radius,
                opacity: opacity,
                tint: palette[tintIndex]
            )
        }
    }()

    var body: some View {
        Canvas { context, size in
            for star in Self.stars {
                let r = star.radius * scale
                let rect = CGRect(
                    x: star.x * size.width - r * 0.5,
                    y: star.y * size.height - r * 0.5,
                    width: r,
                    height: r
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(star.tint.opacity(star.opacity))
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
