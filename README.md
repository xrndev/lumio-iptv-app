<p align="center">
  <img src="assets/branding/lumio_icon_round.png" width="112" alt="Lumio logo">
</p>

<h1 align="center">Lumio</h1>

<p align="center">
  <b>English</b> · <a href="README.es.md">Español</a>
</p>

<p align="center">
  An IPTV player built with Flutter: one codebase for Android, Android TV / Fire TV, iOS, Windows, macOS and Linux.<br>
  Designed for playlists of 50,000+ channels without freezing the UI.
</p>

<p align="center">
  <a href="https://buymeacoffee.com/xrndev"><img src="https://img.shields.io/badge/Buy%20me%20a%20coffee-xrndev-FFDD00?logo=buymeacoffee&logoColor=black" alt="Buy me a coffee"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-blue" alt="GPL-3.0 license"></a>
</p>

> **Status: early prototype.** Hand-tested on Windows and on a Fire TV Stick 4K Max; other platforms only have automated tests. Lumio ships with no channels or playlists: bring your own source.

## Features

- **Sources:** M3U by URL, local file and Xtream Codes (live, movies, series, catch-up). The source is stored encrypted and restored automatically.
- **Fast:** 50,000 channels parsed in ~370 ms; playlists cached on disk so the app starts without a network.
- **Player** (`media_kit`/libmpv, hardware decoding, 4K/HEVC) with automatic error recovery, audio/subtitle tracks, ±10 s seeking and keyboard shortcuts.
- **Library:** favorites, recents and continue watching, transferable between devices with a code. Global search and a "Now / Next" guide.
- **Chromecast** and **TV mode** (Fire TV / Android TV remote, D-Pad focus).
- **English and Spanish:** an `ES | EN` language switch in the menu (and in Settings); it follows the system language by default.
- Adaptive UI (phone, tablet, desktop, TV), dark theme and accessibility (keyboard, screen reader).

Pending: automatic sync, full XMLTV EPG, parental controls, multi-screen, native PiP. Details and verification status in [`CLAUDE.md`](CLAUDE.md) (in Spanish).

## Install

Download the package from the latest release in [Releases](../../releases):

| System | Package | How to install |
|---|---|---|
| Windows 10/11 | `Lumio-windows.zip` | Unzip and run `Install.cmd` (no admin needed). |
| Linux | `Lumio-linux-x64.tar.gz` | Unzip and run `./install.sh`. |
| macOS | `Lumio-macos.zip` | Drag to Applications; unsigned: right-click → Open. |
| Android / Fire TV | `Lumio-android.apk` | Install the APK (unknown sources). Fire OS 6+; on Fire TV: `./scripts/android/install-device.ps1 -Ip <IP>` with ADB debugging on. |
| iOS | — | Not distributed yet (needs Apple signing). |

## Development

```powershell
./scripts/setup.ps1     # Windows  (./scripts/setup.sh on macOS / Linux): installs Flutter and dependencies
flutter pub get
flutter run -d windows  # or linux / macos / android
flutter analyze && flutter test
```

Local packages: `./scripts/package-windows.ps1 -Install` (Windows) or `./scripts/package.sh` (Linux/macOS). Architecture, layers and conventions: [`CLAUDE.md`](CLAUDE.md).

### Translations

UI strings live in `lib/l10n/app_es.arb` (the template) and `lib/l10n/app_en.arb`. To add or change a string, edit **both** files and run `flutter gen-l10n`; in code use `AppLocalizations.of(context).key`. For a new language: copy `app_en.arb` to `app_<code>.arb`, translate it, then add the code to `supportedLanguageCodes` (`lib/features/settings/locale_providers.dart`) and its name to `languageNames` (`language_switcher.dart`).

## Contributing

1. **Fork** the repository and clone it.
2. **Create a branch** from `main` with a descriptive name:
   ```bash
   git checkout main && git pull
   git checkout -b feat/my-change      # or fix/..., docs/...
   ```
3. **Make your changes** following the conventions in [`CLAUDE.md`](CLAUDE.md) (layers, accessibility, a unit test for every new parser, strings in both `.arb` files). Before pushing:
   ```bash
   flutter analyze && flutter test
   ```
4. **Small, clear commits**, in the imperative (`Fix focus on the sidebar`).
5. **Push the branch and open a Pull Request** against `main`:
   ```bash
   git push -u origin feat/my-change
   ```
   Explain what changes and why, and which platform you tested on. Add a screenshot if the UI changes.
6. `main` is **protected**: no direct pushes, and the PR must pass the `calidad` check (analysis + tests) before it can be merged.

For bugs or ideas, open an *issue* first. By contributing you agree that your work is released under the GPL-3.0 license.

## Support the project

If Lumio is useful to you, you can buy me a coffee:

<a href="https://buymeacoffee.com/xrndev"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=☕&slug=xrndev&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" alt="Buy me a coffee" height="48"></a>

## Legal notice

Lumio is only a player: it does not provide, host or recommend any content. You are responsible for using only sources you have the right to use.
