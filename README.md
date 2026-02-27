<p align="center">
  <h1 align="center">Magic Teleprompter</h1>
  <p align="center">
    A native macOS teleprompter that floats over everything.<br>
    Built with SwiftUI. Zero dependencies.
  </p>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS_26+-black?logo=apple" alt="Platform">
  <img src="https://img.shields.io/badge/swift-6.2-F05138?logo=swift&logoColor=white" alt="Swift">
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License">
  <img src="https://img.shields.io/badge/dependencies-0-brightgreen" alt="Dependencies">
</p>

---

## Demo

<details>
<summary>See it in action</summary>
<br>
<p align="center">
  <img src=".github/demo.gif" alt="Magic Teleprompter demo" width="720">
</p>
</details>

## Get Started

```bash
swift build && swift run MagicTeleprompter
```

Or open `Package.swift` in Xcode and hit **Cmd+R**. No `.xcodeproj` needed.

## Features

| Feature | Details |
|---|---|
| **Sentence-by-sentence pacing** | Auto-advances based on word count and WPM setting |
| **Always-on-top overlay** | Floats above all windows, lives in your menu bar |
| **Hide from recordings** | Invisible to OBS, Screen Studio, and all macOS capture APIs |
| **Mirror mode** | Horizontal flip for beam splitter / reflection setups |
| **3-2-1 countdown** | Optional countdown before playback begins |
| **Script editor** | Import/export `.txt`, autosave, live word count |
| **Speed control** | 80 - 400 WPM with slider and keyboard shortcuts |
| **Font sizing** | 20 - 72pt, adjustable on the fly |
| **Glass UI** | Material backgrounds with frosted control bar |

## Keyboard Shortcuts

| Key | Action |
|---|---|
| `Space` | Play / Pause |
| `Right` / `Left` | Next / Previous sentence |
| `Up` / `Down` | Increase / Decrease speed |
| `Cmd +` / `Cmd -` | Increase / Decrease font size |
| `M` | Toggle mirror mode |

## Architecture

```
MagicTeleprompter/
  MagicTeleprompterApp.swift   @main entry point
  AppDelegate.swift            Window lifecycle, menu bar, screen capture hiding
  Engine/
    PlaybackEngine.swift       Playback state, timing, WPM, UserDefaults persistence
  Models/
    ScriptStore.swift          Script text, autosave, import/export
  Views/
    TeleprompterView.swift     Sentence display, controls, keyboard handling
    SettingsView.swift         Settings sheet with toggles and script editor
```

**Design decisions:**

- **Pure SwiftUI + AppKit** — no external dependencies, no CocoaPods, no SPM packages
- **`NSWindow.sharingType = .none`** — uses the macOS capture exclusion API to hide from screen recording software
- **Sentence pacing** — display duration = `wordCount / WPM * 60` with a 1.2s minimum floor
- **Reactive persistence** — `@Published` properties with `didSet` writing to `UserDefaults`

## Requirements

- macOS 26+
- Xcode 26+ / Swift 6.2+

## License

[MIT](LICENSE)
