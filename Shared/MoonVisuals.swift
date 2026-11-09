import SwiftUI

// MARK: - Widget sizes

enum MoonWidgetSize {
    case small
    case medium
    case large
}

/// Widgets rendered by macOS in accented/clear mode lose their colored
/// background and get a monochrome treatment. The moon has to switch from a
/// shaded sphere to a white-on-glass phase drawing so the phase stays legible.
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

        // Limb semicircle: right side for the lit shape, left for the shadow.
        let limbStart = -Double.pi / 2
        let limbEnd = Double.pi / 2
        let limbDirection: Double = lit ? 1 : -1
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

// MARK: - Moon disc

struct MoonDisc: View {
    let phase: Double
    let size: CGFloat
    var detailed: Bool = true
    var glow: Bool = true
    var style: MoonRenderStyle = .fullColor

    private var illumination: Double {
        (1 - cos(2 * Double.pi * (phase - floor(phase)))) / 2
    }

    var body: some View {
        Group {
            if style == .accented {
                accentedDisc
            } else {
                disc
            }
        }
        .frame(width: size, height: size)
        .background(alignment: .center) {
            if glow && style == .fullColor {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                glowColor.opacity(0.12 + 0.22 * illumination),
                                Color(red: 0.60, green: 0.64, blue: 1.00).opacity(0.05),
                                .clear
                            ],
                            center: .center,
                            startRadius: size * 0.28,
                            endRadius: size * 0.78
                        )
                    )
                    .frame(width: size * 1.65, height: size * 1.65)
                    .blur(radius: size * 0.045)
                    .allowsHitTesting(false)
            }
        }
    }

    private var glowColor: Color {
        switch style {
        case .fullColor: return Color(red: 1.00, green: 0.90, blue: 0.72)
        case .accented: return .white
        }
    }

    // MARK: Accented (clear / tinted / dimmed widgets)

    private var accentedDisc: some View {
        ZStack {
            // Only a whisper of earthshine. The unlit part is deliberately
            // transparent so a new moon reads as an outlined disc rather than
            // a solid full moon on a bright glass widget.
            Circle()
                .fill(.white.opacity(0.035))

            MoonPhaseShape(phase: phase, lit: true)
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.99),
                            .white.opacity(0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .strokeBorder(
                    .white.opacity(0.52),
                    lineWidth: max(0.65, size / 190)
                )
        }
        .clipShape(Circle())
        .shadow(color: .white.opacity(0.08 + 0.22 * illumination), radius: size * 0.08)
    }

    // MARK: Full color

    private var disc: some View {
        ZStack {
            MoonSurface(detailed: detailed)

            MoonPhaseShape(phase: phase, lit: false)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.012, green: 0.030, blue: 0.090).opacity(0.78),
                            Color(red: 0.002, green: 0.006, blue: 0.024).opacity(0.88)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // A soft bloom along the illuminated limb keeps very thin
            // crescents readable without changing the geometry.
            MoonPhaseShape(phase: phase, lit: true)
                .fill(
                    Color(red: 1.0, green: 0.92, blue: 0.76)
                        .opacity(0.18 + 0.16 * illumination)
                )
                .blur(radius: size * 0.020)

            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.38),
                            Color.white.opacity(0.08),
                            Color(red: 0.65, green: 0.70, blue: 1.0).opacity(0.16)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(0.55, size / 200)
                )
        }
        .clipShape(Circle())
        .shadow(
            color: Color(red: 1.0, green: 0.88, blue: 0.68)
                .opacity(0.06 + 0.20 * illumination),
            radius: size * 0.10
        )
        .shadow(
            color: Color(red: 0.48, green: 0.58, blue: 1.0).opacity(0.16),
            radius: size * 0.09
        )
    }
}

// MARK: - Surface

private struct MoonSurface: View {
    let detailed: Bool

    private struct Mare {
        let x: CGFloat
        let y: CGFloat
        let radius: CGFloat
        let opacity: Double
        let blur: CGFloat
    }

    private static let maria: [Mare] = [
        Mare(x: 0.33, y: 0.31, radius: 0.19, opacity: 0.16, blur: 0.035),
        Mare(x: 0.51, y: 0.36, radius: 0.12, opacity: 0.14, blur: 0.028),
        Mare(x: 0.63, y: 0.47, radius: 0.13, opacity: 0.12, blur: 0.030),
        Mare(x: 0.22, y: 0.52, radius: 0.20, opacity: 0.11, blur: 0.040),
        Mare(x: 0.44, y: 0.71, radius: 0.14, opacity: 0.09, blur: 0.032)
    ]

    private struct Crater {
        let x: CGFloat
        let y: CGFloat
        let radius: CGFloat
        let opacity: Double
    }

    private static let craters: [Crater] = [
        Crater(x: 0.62, y: 0.27, radius: 0.030, opacity: 0.13),
        Crater(x: 0.31, y: 0.60, radius: 0.024, opacity: 0.12),
        Crater(x: 0.72, y: 0.56, radius: 0.021, opacity: 0.11),
        Crater(x: 0.39, y: 0.20, radius: 0.018, opacity: 0.10),
        Crater(x: 0.55, y: 0.63, radius: 0.034, opacity: 0.12),
        Crater(x: 0.46, y: 0.77, radius: 0.019, opacity: 0.11),
        Crater(x: 0.25, y: 0.37, radius: 0.016, opacity: 0.09)
    ]

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let disc = Path(ellipseIn: rect)
            context.clip(to: disc)

            context.fill(
                disc,
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: Color(red: 1.000, green: 0.985, blue: 0.930), location: 0.00),
                        .init(color: Color(red: 0.960, green: 0.930, blue: 0.850), location: 0.45),
                        .init(color: Color(red: 0.840, green: 0.800, blue: 0.700), location: 0.78),
                        .init(color: Color(red: 0.680, green: 0.635, blue: 0.530), location: 1.00)
                    ]),
                    center: CGPoint(x: size.width * 0.36, y: size.height * 0.30),
                    startRadius: 0,
                    endRadius: size.width * 0.92
                )
            )

            if detailed {
                for mare in Self.maria {
                    var mareContext = context
                    mareContext.addFilter(.blur(radius: size.width * mare.blur))
                    let mareRect = CGRect(
                        x: (mare.x - mare.radius / 2) * size.width,
                        y: (mare.y - mare.radius / 2) * size.height,
                        width: mare.radius * size.width,
                        height: mare.radius * size.height
                    )
                    mareContext.fill(
                        Path(ellipseIn: mareRect),
                        with: .color(Color(red: 0.42, green: 0.39, blue: 0.32).opacity(mare.opacity))
                    )
                }

                for crater in Self.craters {
                    let craterRect = CGRect(
                        x: (crater.x - crater.radius / 2) * size.width,
                        y: (crater.y - crater.radius / 2) * size.height,
                        width: crater.radius * size.width,
                        height: crater.radius * size.height
                    )
                    var craterContext = context
                    craterContext.addFilter(.blur(radius: size.width * 0.004))
                    craterContext.fill(
                        Path(ellipseIn: craterRect),
                        with: .color(Color(red: 0.35, green: 0.32, blue: 0.26).opacity(crater.opacity))
                    )
                }
            }

            // Darker limb, a little atmosphere around the edge.
            context.fill(
                disc,
                with: .radialGradient(
                    Gradient(colors: [
                        .clear,
                        Color(red: 0.08, green: 0.09, blue: 0.15).opacity(0.30)
                    ]),
                    center: CGPoint(x: size.width / 2, y: size.height / 2),
                    startRadius: size.width * 0.28,
                    endRadius: size.width * 0.53
                )
            )

            // Cool specular wash from the upper left.
            context.fill(
                disc,
                with: .radialGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.16),
                        .clear
                    ]),
                    center: CGPoint(x: size.width * 0.30, y: size.height * 0.24),
                    startRadius: 0,
                    endRadius: size.width * 0.55
                )
            )
        }
    }
}

// MARK: - Background

struct MoonBackground: View {
    let size: MoonWidgetSize

    var body: some View {
        GeometryReader { proxy in
            let dimensions = proxy.size
            let glowCenter = glowCenter(for: dimensions)
            let longestSide = max(dimensions.width, dimensions.height)

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.060, green: 0.085, blue: 0.180),
                        Color(red: 0.024, green: 0.038, blue: 0.085),
                        Color(red: 0.010, green: 0.016, blue: 0.038)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        Color(red: 0.44, green: 0.47, blue: 0.96).opacity(0.38),
                        Color(red: 0.20, green: 0.24, blue: 0.70).opacity(0.13),
                        .clear
                    ],
                    center: glowCenter,
                    startRadius: 0,
                    endRadius: longestSide * 0.82
                )

                RadialGradient(
                    colors: [
                        Color(red: 0.18, green: 0.58, blue: 0.58).opacity(0.16),
                        .clear
                    ],
                    center: UnitPoint(x: 0.96, y: 0.94),
                    startRadius: 0,
                    endRadius: longestSide * 0.74
                )

                RadialGradient(
                    colors: [
                        Color(red: 0.88, green: 0.64, blue: 0.42).opacity(0.07),
                        .clear
                    ],
                    center: UnitPoint(x: 0.03, y: 0.02),
                    startRadius: 0,
                    endRadius: longestSide * 0.55
                )

                StarField()

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.065),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )

                RadialGradient(
                    colors: [
                        .clear,
                        Color.black.opacity(0.26)
                    ],
                    center: .center,
                    startRadius: longestSide * 0.20,
                    endRadius: longestSide * 0.78
                )
            }
            .frame(width: dimensions.width, height: dimensions.height)
        }
    }

    private func glowCenter(for dimensions: CGSize) -> UnitPoint {
        switch size {
        case .small:
            return UnitPoint(x: 0.50, y: 0.42)
        case .medium:
            return UnitPoint(x: 0.24, y: 0.50)
        case .large:
            return UnitPoint(x: 0.50, y: 0.34)
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
