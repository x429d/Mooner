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

    /// Overrides the asset-catalog texture for off-bundle renderers
    /// (icon generation CLI); widgets and the app use the catalog image.
    var textureOverride: Image? = nil

    /// Tames the bloom for small canvases like the app icon, where the
    /// default halo would wash out the whole background.
    var glowMultiplier: Double = 1
    var haloScaleMultiplier: CGFloat = 1

    /// Keeps the bloom hugging the disc instead of washing the card centre,
    /// which would leave the box corners looking vignetted (small/medium).
    var compactGlow: Bool = false

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
        let base: Double
        if systemAccent { base = isMini ? 0.08 : 0.16 }
        else { base = style == .fullColor ? 0.30 : 0.32 }
        return base * glowMultiplier
    }

    private var haloScale: CGFloat {
        let base: CGFloat
        if compactGlow { base = 1.16 }
        else if systemAccent { base = isMini ? 1.4 : 1.8 }
        else { base = 1.8 }
        return base * haloScaleMultiplier
    }

    private var haloExtent: CGFloat { compactGlow ? 0.56 : 0.95 }

    private var haloStops: [Gradient.Stop] {
        if compactGlow {
            return [
                .init(color: .clear, location: 0),
                .init(color: .clear, location: 0.88),
                .init(color: glowColor.opacity(glowOpacity), location: 0.93),
                .init(color: glowColor.opacity(glowOpacity * 0.25), location: 0.97),
                .init(color: .clear, location: 1)
            ]
        }
        return [
            .init(color: .clear, location: 0),
            .init(color: .clear, location: 0.52),
            .init(color: glowColor.opacity(glowOpacity), location: 0.62),
            .init(color: glowColor.opacity(glowOpacity * 0.25), location: 0.80),
            .init(color: .clear, location: 1)
        ]
    }

    private var haloBlur: CGFloat {
        if compactGlow { return 0.04 }
        if systemAccent { return isMini ? 0.05 : 0.10 }
        return 0.10
    }

    private var resolvedEarthshineOpacity: Double {
        systemAccent ? max(earthshineOpacity, 0.5) : max(earthshineOpacity, 0.38)
    }

    private var earthshineBrightness: Double {
        systemAccent ? -0.15 : -0.45
    }

    var body: some View {
        ZStack {
            // In the native clear/tinted widget appearance, dark pixels turn
            // into alpha. A whisper of a disc keeps the silhouette readable
            // against busy wallpapers instead of a bare hole.
            if systemAccent {
                Circle()
                    .fill(.white.opacity(0.06))
            }

            // In the native clear/tinted widget appearance, dark pixels turn
            // into alpha. A full earthshine disc then reads as a full moon, so
            // the unlit side is left transparent and defined by a rim instead.
            if !systemAccent {
                texture
                    .brightness(earthshineBrightness)
                    .opacity(resolvedEarthshineOpacity)
            }

            // A frosted base under the lit texture keeps the maria from
            // turning into translucent holes once luminance becomes alpha.
            if systemAccent {
                MoonPhaseMask(phase: phase)
                    .fill(.white.opacity(0.45))
                    .blur(radius: size * 0.035)
            }

            texture
                .brightness(systemAccent ? 0.10 : 0.16)
                .contrast(systemAccent ? 1.05 : 1.06)
                .mask(
                    MoonPhaseMask(phase: phase)
                        .fill(.white)
                        .blur(radius: size * 0.035)
                )

            if !systemAccent {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .clear,
                                .black.opacity(0.30)
                            ],
                            center: .center,
                            startRadius: size * 0.30,
                            endRadius: size * 0.5
                        )
                    )
                    .blendMode(.multiply)
            }

            if systemAccent {
                Circle()
                    .strokeBorder(
                        .white.opacity(isMini ? 0.6 : 0.42),
                        lineWidth: isMini ? 1.0 : 1.1
                    )
            } else {
                Circle()
                    .strokeBorder(rimLight, lineWidth: 1)
            }
        }
        .compositingGroup()
        .clipShape(Circle())
        .shadow(
            color: glowColor.opacity(glowOpacity * 0.7),
            radius: size * (compactGlow ? 0.08 : 0.12),
            x: isWaxing ? size * 0.02 : -size * 0.02,
            y: 0
        )
        .background(alignment: .center) {
            Circle()
                .fill(
                    // Clear inside the limb so the bloom never washes out the
                    // translucent earthshine side; peaks just outside the disc.
                    RadialGradient(
                        stops: haloStops,
                        center: .center,
                        startRadius: 0,
                        endRadius: size * haloExtent
                    )
                )
                .frame(
                    width: size * haloScale,
                    height: size * haloScale
                )
                .blur(radius: size * haloBlur)
                .allowsHitTesting(false)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var texture: some View {
        (textureOverride ?? Image("MoonTexture"))
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
