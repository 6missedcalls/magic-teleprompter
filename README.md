# Magic Teleprompter

A lightweight, native macOS teleprompter built with SwiftUI. Runs as a floating overlay with sentence-by-sentence display, glass-effect controls, and zero external dependencies.

## Requirements

- macOS 26+
- Xcode 26+ / Swift 6.2+

## Build & Run

```bash
# Build
swift build

# Run
swift run MagicTeleprompter

# Test
swift test
```

Or open `Package.swift` in Xcode and press **Cmd+R**.

## Features

- **Sentence-by-sentence display** with automatic pacing based on word count and WPM
- **Floating overlay** window that stays on top of all apps
- **Menu bar app** with status item toggle (no Dock icon)
- **Mirror mode** for beam splitter setups
- **Hide from recordings** toggle to exclude the window from OBS, Screen Studio, and all macOS screen capture APIs
- **Optional 3-2-1 countdown** before playback begins
- **Script editor** with import/export (.txt), autosave, and live word count
- **Adjustable speed** (80-400 WPM) and **font size** (20-72pt)
- **Glass-effect UI** with material backgrounds and frosted controls

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| Space | Play / Pause |
| Right Arrow | Next sentence |
| Left Arrow | Previous sentence |
| Up Arrow | Increase speed |
| Down Arrow | Decrease speed |
| Cmd + `+` | Increase font size |
| Cmd + `-` | Decrease font size |
| M | Toggle mirror mode |

## Architecture

```
MagicTeleprompter/
  MagicTeleprompterApp.swift   # App entry point (@main)
  AppDelegate.swift            # Window management, status item, screen capture hiding
  Models/
    ScriptStore.swift          # Script text persistence, import/export
  Engine/
    PlaybackEngine.swift       # Playback state, timing, speed, settings (UserDefaults)
  Views/
    TeleprompterView.swift     # Main display, controls, keyboard handling
    SettingsView.swift         # Settings sheet with toggles and script editor
```

### Design Decisions

- **No external dependencies** — pure SwiftUI + AppKit bridging only where needed
- **`ObservableObject` + `@Published`** — reactive state with UserDefaults persistence via `didSet`
- **`NSWindow.sharingType = .none`** — excludes the window from `CGWindowListCreateImage` and `SCStream` capture APIs when hide-from-recordings is enabled
- **Sentence-based pacing** — display duration scales with word count (`words / WPM * 60`), with a 1.2s minimum floor
- **App Sandbox disabled** — required for floating window level (`.floating`) and `sharingType` control

## Settings Persistence

All preferences are saved to UserDefaults and restored on launch:

- Speed (WPM)
- Font size
- Mirror mode
- Countdown toggle
- Hide from recordings
- Script text

## License

MIT
