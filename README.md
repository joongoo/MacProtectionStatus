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

## License

MIT
