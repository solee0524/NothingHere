# NothingHere

A macOS panic-button utility. One key press hides all windows, pauses media playback, and opens a cover document — making your screen look like you were doing something else entirely.

## Features

- **Panic Hotkey** — Configurable global hotkey triggers all actions simultaneously
- **Hide All Windows** — Minimizes or hides every visible window on screen
- **Pause Media** — Stops any currently playing audio or video
- **Open Cover Document** — Launches a pre-configured "nothing to see here" file
- **Guard Mode** — Arms a single-keystroke trigger from the menu bar; any key press fires the panic action and disarms
- **Menu Bar App** — Lives in the menu bar with a dynamic icon showing armed/disarmed state
- **Auto-Update** — Built-in update support via Sparkle

## System Requirements

- macOS 15.0+
- Accessibility permission (required for global hotkey and window management)

## Installation

Download the latest DMG from [GitHub Releases](https://github.com/solee0524/NothingHere/releases).

> This app cannot be sandboxed and is distributed outside the Mac App Store.

## Permissions

On first launch, NothingHere will prompt you to grant **Accessibility** access:

**System Settings → Privacy & Security → Accessibility**

This permission is required for:
- Global hotkey detection
- Hiding windows across all applications

## Building from Source

**Requirements:** Xcode 16.2+, Swift 5

```bash
git clone https://github.com/solee0524/NothingHere.git
cd NothingHere
```

Open the project in Xcode and build (Cmd+R).

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
