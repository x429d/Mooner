// Regenerates the static AppIcon PNGs from the shared icon artwork.
//
//   swiftc -O Tools/render-icon.swift Shared/MoonVisuals.swift \
//     Shared/MoonPhaseView.swift Shared/MoonAppIcon.swift \
//     -o .build/iconrender -framework AppKit -framework SwiftUI -framework WidgetKit
//   .build/iconrender Mooner/Assets.xcassets/AppIcon.appiconset [phase]
//
// `phase` defaults to 0.5 (full moon): the bundle icon stays timeless while
// the running app shows the live phase on its Dock tile.

import AppKit
import SwiftUI

@main
struct RenderIcon {
    static func main() {
        let arguments = CommandLine.arguments
        guard arguments.count >= 2 else {
            FileHandle.standardError.write(Data("usage: render-icon <out-dir> [phase]\n".utf8))
            exit(1)
        }
        let outDirectory = arguments[1]
        let phase = arguments.count >= 3 ? Double(arguments[2]) ?? 0.5 : 0.5

        do {
            try FileManager.default.createDirectory(
                atPath: outDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            FileHandle.standardError.write(Data("cannot create \(outDirectory): \(error)\n".utf8))
            exit(1)
        }

        let texturePath = "Shared/Assets.xcassets/MoonTexture.imageset/moon-texture.jpg"
        guard let nsTexture = NSImage(contentsOfFile: texturePath) else {
            FileHandle.standardError.write(Data("cannot read \(texturePath)\n".utf8))
            exit(1)
        }
        let texture = Image(nsImage: nsTexture)

        let sizes: [(String, Int)] = [
            ("icon_16x16", 16),
            ("icon_16x16@2x", 32),
            ("icon_32x32", 32),
            ("icon_32x32@2x", 64),
            ("icon_128x128", 128),
            ("icon_128x128@2x", 256),
            ("icon_256x256", 256),
            ("icon_256x256@2x", 512),
            ("icon_512x512", 512),
            ("icon_512x512@2x", 1024)
        ]

        for (name, pixels) in sizes {
            let renderer = ImageRenderer(
                content: MoonAppIcon(phase: phase, size: CGFloat(pixels), texture: texture)
            )
            renderer.scale = 1
            guard let image = renderer.nsImage,
                  let tiff = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff),
                  let png = bitmap.representation(using: .png, properties: [:]) else {
                FileHandle.standardError.write(Data("render failed for \(name)\n".utf8))
                exit(1)
            }
            let url = URL(fileURLWithPath: outDirectory).appendingPathComponent("\(name).png")
            do {
                try png.write(to: url)
                print("wrote \(name).png (\(pixels)px)")
            } catch {
                FileHandle.standardError.write(Data("write failed for \(name): \(error)\n".utf8))
                exit(1)
            }
        }
    }
}
