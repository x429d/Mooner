import SwiftUI

/// The app icon artwork: the same textured lunar sphere the widgets use,
/// floating in deep space inside the macOS squircle.
///
/// `phase` is a 0...1 cycle fraction, so the icon can show the live moon.
/// `texture` overrides the asset-catalog lookup for off-bundle renderers.
struct MoonAppIcon: View {
    let phase: Double
    let size: CGFloat
    var texture: Image? = nil

    private var cornerRadius: CGFloat { size * 0.2237 }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0x141C3C),
                    Color(hex: 0x0B1020),
                    Color(hex: 0x05070F)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color(red: 0.30, green: 0.42, blue: 0.85).opacity(0.34),
                    .clear
                ],
                center: UnitPoint(x: 0.16, y: 0.08),
                startRadius: 0,
                endRadius: size * 0.70
            )

            StarField(scale: size / 338)
                .opacity(0.7)

            MoonPhaseView(
                phase: phase,
                size: size * 0.62,
                style: .fullColor,
                textureOverride: texture,
                glowMultiplier: 0.45,
                haloScaleMultiplier: 0.78
            )

            RadialGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.32)
                ],
                center: .center,
                startRadius: size * 0.36,
                endRadius: size * 0.78
            )

            LinearGradient(
                colors: [
                    Color.white.opacity(0.07),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .center
            )
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.28),
                            .white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(1, size * 0.004)
                )
        }
    }
}
