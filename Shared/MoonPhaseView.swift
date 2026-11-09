import SwiftUI
import WidgetKit

/// The illuminated part of the lunar disc, used as a soft mask over the
/// full-moon texture. The blur is applied by the view to soften the
/// terminator into a spherical falloff.
struct MoonPhaseMask: Shape {
    let phase: Double

    func path(in rect: CGRect) -> Path {
        MoonPhaseShape(phase: phase, lit: true).path(in: rect)
    }
}

/// A layered, textured lunar sphere.
///
/// The full disc is first laid down as earthshine. The illuminated texture is
/// then masked by the current phase, and a limb-darkening pass and a rim light
/// restore the spherical volume that a flat vector cut loses.
struct MoonPhaseView: View {
    let phase: Double
    let size: CGFloat
    var style: MoonRenderStyle = .fullColor
    var isMini: Bool = false
    var earthshineOpacity: Double = 0.14

    /// The native widget's clear/tinted treatment turns dark pixels into
    /// alpha. Only there do we lift the earthshine to keep the whole disc.
    var systemAccent: Bool = false

    private var isWaxing: Bool {
        let normalized = phase - floor(phase)
        return normalized < 0.5
    }

    private var glowColor: Color {
        style == .fullColor
            ? Color(red: 1.0, green: 0.973, blue: 0.906) // #FFF8E7
            : Color(red: 0.72, green: 0.81, blue: 1.0)
    }

    private var glowOpacity: Double {
        style == .fullColor ? 0.18 : 0.26
    }

    private var resolvedEarthshineOpacity: Double {
        systemAccent ? max(earthshineOpacity, 0.5) : earthshineOpacity
    }

    private var earthshineBrightness: Double {
        systemAccent ? -0.15 : -0.4
    }

    var body: some View {
        ZStack {
            texture
                .brightness(earthshineBrightness)
                .opacity(resolvedEarthshineOpacity)

            texture
                .brightness(systemAccent ? 0 : 0.06)
                .contrast(systemAccent ? 1.0 : 1.04)
                .mask(
                    MoonPhaseMask(phase: phase)
                        .fill(.white)
                        .blur(radius: size * 0.045)
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .clear,
                            .black.opacity(0.42)
                        ],
                        center: .center,
                        startRadius: size * 0.25,
                        endRadius: size * 0.5
                    )
                )
                .blendMode(.multiply)

            Circle()
                .strokeBorder(rimLight, lineWidth: 1)
        }
        .compositingGroup()
        .clipShape(Circle())
        .shadow(
            color: glowColor.opacity(glowOpacity * 0.55),
            radius: size * 0.10,
            x: isWaxing ? size * 0.02 : -size * 0.02,
            y: 0
        )
        .background(alignment: .center) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            glowColor.opacity(glowOpacity),
                            glowColor.opacity(glowOpacity * 0.22),
                            .clear
                        ],
                        center: .center,
                        startRadius: size * 0.30,
                        endRadius: size * 0.95
                    )
                )
                .frame(width: size * 2.0, height: size * 2.0)
                .blur(radius: size * 0.11)
                .allowsHitTesting(false)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var texture: some View {
        Image("MoonTexture")
            .resizable()
            .interpolation(.high)
            .widgetAccentedRenderingMode(.fullColor)
            .frame(width: size, height: size)
    }

    private var rimLight: LinearGradient {
        LinearGradient(
            colors: isWaxing
                ? [.white.opacity(0.04), .white.opacity(0.18)]
                : [.white.opacity(0.18), .white.opacity(0.04)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
