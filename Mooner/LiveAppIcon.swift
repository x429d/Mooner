import AppKit
import SwiftUI

/// Keeps the Dock / Cmd-Tab icon in sync with the real moon: the bundle icon
/// is a timeless full moon, but the running app redraws its tile with the
/// live phase every half hour and right after wake from sleep.
@MainActor
enum LiveAppIcon {
    private static var timer: Timer?
    private static var wakeObserver: NSObjectProtocol?

    static func start() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 1_800, repeats: true) { _ in
            MainActor.assumeIsolated { update() }
        }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated { update() }
        }
    }

    static func update() {
        let phase = LunarMath.phaseFraction(at: Date())
        let renderer = ImageRenderer(content: MoonAppIcon(phase: phase, size: 512))
        renderer.scale = 1
        guard let image = renderer.nsImage else { return }
        NSApplication.shared.applicationIconImage = image
    }
}
