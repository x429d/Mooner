# Changelog

## Unreleased

### Added

- Test suite (`MoonerTests`): golden 2026 ephemeris moments, astronomy
  invariants across a century of sampled dates, phase-name boundaries,
  snapshot integration, phase-shape geometry and the formatting rules.
- CI now runs the tests and a Release build in addition to the Debug build.

### Changed

- Swift 6 language mode with complete concurrency checking
  (`LiveAppIcon` is now a `@MainActor` enum; the widget reload
  auto-reset uses a `Task` instead of `DispatchQueue`).
- Widget gallery display name: "Moon" → "Mooner".

### Fixed

- `Tools/render-icon.swift` now creates its output directory instead of
  failing on a fresh path.
- `MoonPhaseEvent` carries its own cycle fraction (`targetFraction`);
  the silent new-moon fallback of `MoonPhaseName.targetFraction` for
  intermediate phases is gone.
- Removed a never-triggering forecast filter (`forecastPhases`): upcoming
  events are always at least a lunation ahead of the current phase name.

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
