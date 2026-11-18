import SwiftUI
import WidgetKit

// MARK: - Environment texture override

private struct MoonTextureEnvironmentKey: EnvironmentKey {
    static let defaultValue: Image? = nil
}

extension EnvironmentValues {
    var moonTextureOverride: Image? {
        get { self[MoonTextureEnvironmentKey.self] }
        set { self[MoonTextureEnvironmentKey.self] = newValue }
    }
}

/// The illuminated part of the lunar disc, used as a soft mask over the
/// full-moon texture.
///
/// The terminator follows the exact spherical projection inside the disc, while
/// the sunlit outer limb extends proportionally past the clip circle so that
/// blurring the terminator never pulls the mask inward from the sunlit edge.
struct MoonPhaseMask: Shape {
    let phase: Double

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let normalizedPhase = phase - floor(phase)
        let isWaning = normalizedPhase > 0.5
        let waxingPhase = isWaning ? 1 - normalizedPhase : normalizedPhase
        let terminatorX = radius * CGFloat(cos(2 * Double.pi * waxingPhase))

        // Expand the outer limb outward only as the lit lune opens up, so
        // phase == 0 still has zero area while quarter/gibbous/full phases
        // keep full alpha right up to the circular clip boundary after blur.
        let litOpenness = max(0, (radius - terminatorX) / (2 * radius))
        let outerRadius = radius * (1 + 0.42 * litOpenness)

        let steps = 120
        let limbStart = -Double.pi / 2
        let limbEnd = Double.pi / 2

        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - outerRadius))

        // Outer semicircle on the lit (right) side, padded past the clip edge.
        for index in 1...steps {
            let angle = limbStart + (limbEnd - limbStart) * Double(index) / Double(steps)
            path.addLine(to: CGPoint(
                x: center.x + outerRadius * CGFloat(cos(angle)),
                y: center.y + outerRadius * CGFloat(sin(angle))
            ))
        }

        // Connect smoothly to the south pole of the true lunar disc.
        path.addLine(to: CGPoint(x: center.x, y: center.y + radius))

        // Exact terminator half-ellipse from south pole back to north pole.
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

/// A layered, textured lunar sphere with physically inspired optical bloom,
/// cool earthshine on the night hemisphere, and directional rim lighting.
struct MoonPhaseView: View {
    @Environment(\.moonTextureOverride) private var envTextureOverride

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

    private var normalizedPhase: Double {
        phase - floor(phase)
    }

    private var isWaxing: Bool {
        normalizedPhase < 0.5
    }

    private var waxingEquivalent: Double {
        isWaxing ? normalizedPhase : 1 - normalizedPhase
    }

    /// Approximate illuminated fraction (0 at new moon, 1 at full moon) used
    /// to scale atmospheric bloom and directional rim intensity naturally.
    private var litFraction: Double {
        (1 - cos(2 * Double.pi * normalizedPhase)) / 2
    }

    private var terminatorBlurRadius: CGFloat {
        let ramp = min(1, waxingEquivalent * 10)
        return size * (isMini ? 0.026 : 0.034) * CGFloat(ramp)
    }

    private var glowColor: Color {
        style == .fullColor
            ? Color(red: 1.0, green: 0.96, blue: 0.86)
            : Color(red: 0.78, green: 0.87, blue: 1.0)
    }

    private var outerCoronaColor: Color {
        style == .fullColor
            ? Color(red: 0.42, green: 0.60, blue: 1.0)
            : Color(red: 0.64, green: 0.78, blue: 1.0)
    }

    private var glowOpacity: Double {
        let phaseWeight = 0.42 + 0.58 * litFraction
        let base: Double
        if systemAccent {
            base = isMini ? 0.08 : 0.16
        } else {
            base = style == .fullColor ? 0.36 : 0.32
        }
        return base * phaseWeight * glowMultiplier
    }

    private var haloScale: CGFloat {
        let base: CGFloat
        if isMini { base = 1.28 }
        else if compactGlow { base = 1.38 }
        else if systemAccent { base = 1.50 }
        else { base = 1.64 }
        return base * haloScaleMultiplier
    }

    private var resolvedEarthshineOpacity: Double {
        if systemAccent { return max(earthshineOpacity, 0.5) }
        if style == .accented { return max(earthshineOpacity, isMini ? 0.46 : 0.44) }
        return max(earthshineOpacity, isMini ? 0.44 : 0.40)
    }

    private var earthshineBrightness: Double {
        if systemAccent { return -0.15 }
        if style == .accented { return -0.24 }
        return -0.28
    }

    private var sunlitDirectionX: CGFloat {
        isWaxing ? 1 : -1
    }

    var body: some View {
        ZStack {
            // 1. Base sphere silhouette:
            // In fullColor/glass, a deep selenian base prevents background
            // stars from bleeding through the solid body of the Moon while
            // harmonizing with the card material.
            if systemAccent {
                Circle()
                    .fill(.white.opacity(0.06))
            } else if style == .accented {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.14, green: 0.18, blue: 0.28).opacity(0.62),
                                Color(red: 0.09, green: 0.12, blue: 0.20).opacity(0.76)
                            ],
                            center: UnitPoint(
                                x: 0.5 - Double(sunlitDirectionX) * 0.15,
                                y: 0.5
                            ),
                            startRadius: 0,
                            endRadius: size * 0.52
                        )
                    )
            } else {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.08, green: 0.11, blue: 0.20).opacity(0.88),
                                Color(red: 0.04, green: 0.06, blue: 0.12).opacity(0.94)
                            ],
                            center: UnitPoint(
                                x: 0.5 - Double(sunlitDirectionX) * 0.15,
                                y: 0.5
                            ),
                            startRadius: 0,
                            endRadius: size * 0.52
                        )
                    )
            }

            // 2. Earthshine texture on the shadowed hemisphere:
            // Tinted with cool reflected Earthlight so lunar maria remain
            // delicately visible inside the night side.
            if !systemAccent {
                texture
                    .brightness(earthshineBrightness)
                    .contrast(0.98)
                    .colorMultiply(
                        style == .fullColor
                            ? Color(red: 0.80, green: 0.88, blue: 1.0)
                            : Color(red: 0.86, green: 0.91, blue: 1.0)
                    )
                    .opacity(resolvedEarthshineOpacity)
            }

            // 3. Frosted luminance base for clear/tinted mode so dark maria
            // on the sunlit side do not turn into transparent holes.
            if systemAccent {
                MoonPhaseMask(phase: phase)
                    .fill(.white.opacity(0.46))
                    .blur(radius: terminatorBlurRadius)
            }

            // 4. Sunlit lunar surface with spherical Lambertian shading:
            // Brighter and warmer toward the subsolar limb, with crisp crater
            // contrast along the grazing-angle terminator.
            ZStack {
                texture
                    .brightness(systemAccent ? 0.10 : 0.15)
                    .contrast(systemAccent ? 1.06 : 1.11)
                    .colorMultiply(
                        style == .fullColor && !systemAccent
                            ? Color(red: 1.0, green: 0.988, blue: 0.955)
                            : .white
                    )

                if !systemAccent && !isMini {
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.07),
                            .clear,
                            Color.black.opacity(0.18)
                        ],
                        center: UnitPoint(
                            x: 0.5 + Double(sunlitDirectionX) * 0.28 * (1 - litFraction * 0.5),
                            y: 0.48
                        ),
                        startRadius: size * 0.06,
                        endRadius: size * 0.62
                    )
                    .blendMode(.overlay)
                }
            }
            .mask(
                MoonPhaseMask(phase: phase)
                    .fill(.white)
                    .blur(radius: terminatorBlurRadius)
            )

            // 5. Spherical limb darkening around the perimeter for 3D volume.
            if !systemAccent {
                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .clear, location: 0.66),
                                .init(color: .black.opacity(0.15), location: 0.88),
                                .init(color: .black.opacity(0.30), location: 1.0)
                            ],
                            center: UnitPoint(
                                x: 0.5 + Double(sunlitDirectionX) * 0.08,
                                y: 0.5
                            ),
                            startRadius: 0,
                            endRadius: size * 0.5
                        )
                    )
                    .blendMode(.multiply)
            }

            // 6. Directional optical rim light:
            // Luminous specular edge on the sunlit hemisphere, tapering into a
            // delicate earthshine rim around the shadowed limb.
            if systemAccent {
                Circle()
                    .strokeBorder(
                        accentedRimGradient,
                        lineWidth: isMini ? 1.0 : 1.1
                    )
            } else {
                Circle()
                    .strokeBorder(
                        fullColorRimGradient,
                        lineWidth: isMini ? 0.85 : 1.05
                    )
            }
        }
        .compositingGroup()
        .clipShape(Circle())
        .shadow(
            color: glowColor.opacity(glowOpacity * (compactGlow ? 0.52 : 0.68)),
            radius: size * (isMini ? 0.06 : (compactGlow ? 0.09 : 0.13)),
            x: sunlitDirectionX * size * (1 - CGFloat(litFraction) * 0.65) * 0.03,
            y: 0
        )
        .background(alignment: .center) {
            if !isMini || !systemAccent {
                ZStack {
                    // Continuous optical corona decaying smoothly outward with
                    // same-hue zero alpha.
                    Circle()
                        .fill(
                            RadialGradient(
                                stops: systemAccent
                                    ? [
                                        .init(color: glowColor.opacity(0.0), location: 0.0),
                                        .init(color: glowColor.opacity(0.0), location: 0.56),
                                        .init(color: glowColor.opacity(glowOpacity * 0.55), location: 0.64),
                                        .init(color: glowColor.opacity(glowOpacity * 0.18), location: 0.80),
                                        .init(color: glowColor.opacity(0.0), location: 1.0)
                                    ]
                                    : [
                                        .init(color: glowColor.opacity(glowOpacity * 0.75), location: 0.0),
                                        .init(color: glowColor.opacity(glowOpacity * 0.52), location: 0.45),
                                        .init(color: outerCoronaColor.opacity(glowOpacity * 0.22), location: 0.66),
                                        .init(color: outerCoronaColor.opacity(glowOpacity * 0.06), location: 0.84),
                                        .init(color: outerCoronaColor.opacity(0.0), location: 1.0)
                                    ],
                                center: .center,
                                startRadius: systemAccent ? 0 : size * 0.22,
                                endRadius: size * haloScale * 0.47
                            )
                        )

                    // Directional sunlit limb bloom biased toward the illuminated
                    // hemisphere with startRadius: 0 so there is no inner plateau ring.
                    if !systemAccent && litFraction > 0.03 {
                        Circle()
                            .fill(
                                RadialGradient(
                                    stops: [
                                        .init(color: glowColor.opacity(glowOpacity * 0.62), location: 0.0),
                                        .init(color: glowColor.opacity(glowOpacity * 0.36), location: 0.48),
                                        .init(color: glowColor.opacity(glowOpacity * 0.10), location: 0.76),
                                        .init(color: glowColor.opacity(0.0), location: 1.0)
                                    ],
                                    center: UnitPoint(
                                        x: 0.5 + Double(sunlitDirectionX) * 0.08 * (1 - litFraction * 0.5),
                                        y: 0.5
                                    ),
                                    startRadius: 0,
                                    endRadius: size * haloScale * 0.38
                                )
                            )
                    }
                }
                .frame(width: size * haloScale, height: size * haloScale)
                .allowsHitTesting(false)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var texture: some View {
        (textureOverride ?? envTextureOverride ?? Image("MoonTexture"))
            .resizable()
            .interpolation(.high)
            .widgetAccentedRenderingMode(.fullColor)
            .frame(width: size, height: size)
    }

    private var fullColorRimGradient: LinearGradient {
        let litEdge = glowColor.opacity(isMini ? 0.52 : 0.46)
        let midEdge = Color.white.opacity(0.16)
        let darkEdge = Color(red: 0.68, green: 0.80, blue: 1.0).opacity(isMini ? 0.18 : 0.11)

        return LinearGradient(
            stops: isWaxing
                ? [
                    .init(color: darkEdge, location: 0.0),
                    .init(color: midEdge, location: 0.48),
                    .init(color: litEdge, location: 1.0)
                ]
                : [
                    .init(color: litEdge, location: 0.0),
                    .init(color: midEdge, location: 0.52),
                    .init(color: darkEdge, location: 1.0)
                ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var accentedRimGradient: LinearGradient {
        let litOpacity = isMini ? 0.65 : 0.52
        let darkOpacity = isMini ? 0.34 : 0.22

        return LinearGradient(
            colors: isWaxing
                ? [.white.opacity(darkOpacity), .white.opacity(litOpacity)]
                : [.white.opacity(litOpacity), .white.opacity(darkOpacity)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

