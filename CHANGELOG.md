# Changelog

## 1.0.0 — 2026-11-16

First public open-source release.

- Live moon phase widgets for macOS desktop: Small, Medium, Large.
- Local astronomy (Meeus): phase, illumination, age, principal-phase moments;
  hourly WidgetKit timeline plus entries at exact phase events.
- Medium and Large show the upcoming principal phases with dates.
- Three previewable styles: Color, Glass, Dimmed; rendering adapted to the
  system clear/tinted (dimmed) desktop mode — solid lit side, outlined disc,
  new moon never reads as full.
- Live Dock / Cmd-Tab icon showing the current phase; timeless full-moon
  bundle icon generated from the shared artwork (`Tools/render-icon.swift`).
- Host app with phase/style previews, install instructions and widget reload.
- No network, no account, no location access.
- MIT license for code; CC BY-SA 3.0 for the lunar texture (LICENSE-ASSETS).
