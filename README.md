# MacProtectionStatus

Menu bar app that shows macOS's built-in security status (XProtect, Gatekeeper, FileVault, SIP) in real time.

macOS doesn't need third-party antivirus software — it ships with built-in protection (XProtect, Gatekeeper, FileVault, System Integrity Protection). This app surfaces that real status in your menu bar so you always know what's actually protecting your Mac.

## Download

Grab the latest `.dmg` from the [Releases](../../releases) page, open it, and drag `MacProtectionStatus.app` onto the **Applications** shortcut inside.

The app is currently unsigned (no Apple Developer ID certificate). On first launch, right-click the app → **Open**, or approve it under **System Settings → Privacy & Security → Open Anyway**.

## What it shows

- **XProtect** — built-in malware scanning, with live definition version
- **Gatekeeper** — blocks apps from unidentified developers
- **FileVault** — full-disk encryption status
- **System Integrity Protection (SIP)** — protects core system files

## Features

- Lives in the menu bar only (no Dock icon)
- Optional "Launch at login" toggle in Settings
- Click the icon anytime to see current status

## Build from source

Requires Xcode Command Line Tools (Swift 5.9+, macOS 13+).

```bash
git clone https://github.com/joongoo/MacProtectionStatus.git
cd MacProtectionStatus

# Build a runnable .app bundle
./build_app.sh
open MacProtectionStatus.app

# Or build a distributable .dmg (drag-to-Applications installer)
./build_dmg.sh
```

`build_app.sh` code-signs the bundle: a Developer ID Application certificate
if `security find-identity` finds one installed (or one is passed via the
`DEVELOPER_ID_APPLICATION` env var), otherwise it falls back to an ad-hoc
signature for local use.

### Building the DMG

`build_dmg.sh` requires [`create-dmg`](https://github.com/create-dmg/create-dmg):

```bash
brew install create-dmg
```

It then:

1. Runs `build_app.sh` to produce `MacProtectionStatus.app`.
2. Runs `scripts/generate_dmg_background.swift` to render `Resources/dmg_background.png` —
   the DMG window's background image (app icon → arrow → Applications folder, with an install
   hint). The copy is Korean if the machine *running the build* is set to Korean, English
   otherwise (`Locale.current.language.languageCode`). This only reflects the build machine's
   language, not the end user's, since the image is baked in at build time — there's no runtime
   locale switch inside a DMG.
3. Runs `create-dmg` to lay out a Finder window (app icon, `Applications` symlink, background)
   and compress it into `MacProtectionStatus.dmg`.

We previously shipped a `.pkg` installer (`pkgbuild`) instead — see [archive/README.md](archive/README.md)
for why that was dropped in favor of the DMG.

**Known issue:** on newer macOS, `create-dmg` 1.3.0's bundled AppleScript can fail with
`statusbar visible of container window ... (-10006)`. If you hit that, wrap the `set statusbar
visible to false` lines in `try`/`end try` in
`$(brew --prefix)/Cellar/create-dmg/*/share/create-dmg/support/template.applescript` — it's a
harmless property set failing on newer Finder, not a real error.

## License

MIT
