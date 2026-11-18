# Contributing to Mooner

Thanks for considering a contribution!

## Setup

```sh
brew install xcodegen
xcodegen generate
open Mooner.xcodeproj
```

- macOS 15+, Xcode 16+.
- The `.xcodeproj` is generated from `project.yml`. **After adding, removing or
  renaming files, run `xcodegen generate` and commit the updated
  `project.pbxproj`** — otherwise CI and other contributors won't see them.
- No development team is committed. Pick your own in Xcode, or build with
  `CODE_SIGNING_ALLOWED=NO` for a compile-only check.

## Building & running

```sh
xcodebuild -project Mooner.xcodeproj -scheme Mooner \
  -configuration Debug -derivedDataPath .build/dd \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

Useful launch arguments for visual work (see README for the full list):
`--preview-phase=firstQuarter`, `--preview-style=color|glass|dimmed`.

To refresh desktop widgets after installing a new build over
`/Applications/Mooner.app`, restart the widget daemon: `killall chronod`.

## Testing

```sh
xcodebuild -project Mooner.xcodeproj -scheme Mooner \
  -configuration Debug -derivedDataPath .build/dd \
  -destination 'platform=macOS' test
```

The suite launches the host app briefly; on CI sign ad-hoc with
`CODE_SIGN_IDENTITY=-`. It covers:

- Golden ephemeris moments for 2026 (±10 min: Meeus' truncated series keep
  the error within a few minutes of published ephemerides — timeanddate.com
  or USNO; mind the timezone when you add a case).
- Astronomy invariants across a century of seeded dates: ranges, event
  ordering, cycle periodicity.
- Phase-name boundaries and snapshot integration.
- Phase-shape geometry: no lit area at new moon, half disc at quarters,
  mirrored waning, the shadow lune complementing the lit one.
- The English formatting rules (decimal point, day-month order, countdown
  and full-moon phrases).

When fixing an astronomy bug, add the failing golden case first, then fix
the formulas.

## Guidelines

- Keep the project dependency-free: SwiftUI + WidgetKit + Foundation only.
  Astronomy stays local and deterministic (Meeus), no network, no location.
- Shared rendering lives in `Shared/` and must compile for both the app and
  the widget extension (`APPLICATION_EXTENSION_API_ONLY` — no `NSApplication`
  there; AppKit-only code belongs in `Mooner/`).
- Match the surrounding style: small private views, `MARK:` sections,
  comments that explain *why* (rendering tricks, system behaviors).
- Visual changes: verify with screenshots of all three styles
  (Color / Glass / Dimmed) and all three sizes; the dimmed mode maps dark
  pixels to alpha, so check it separately.
- The icon PNGs are generated with `Tools/render-icon.swift` (see README).
  ImageRenderer output is **not byte-identical across Xcode/SDK versions**:
  regenerate only on purpose, review the result visually, and don't commit
  incidental byte churn from a regenerate-only run.
- Keep new code Swift 6 clean: the project builds in Swift 6 language mode
  with complete concurrency checking.
- Commit messages: English, [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat(widget): …`, `fix(ui): …`, `docs: …`).
- Keep PRs focused; include before/after screenshots for visual changes.

## Reporting bugs

Open an issue with: macOS version, widget size, style (Color/Glass/Dimmed or
system dimmed), and a screenshot if visual. For phase/date accuracy issues,
include the date and your expected value.
