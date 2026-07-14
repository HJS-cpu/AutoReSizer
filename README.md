# AutoReSizer

A modern window management tool for Windows that automatically positions and resizes windows based on user-defined rules.

[![Release](https://img.shields.io/github/v/release/HJS-cpu/AutoReSizer)](https://github.com/HJS-cpu/AutoReSizer/releases) [![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v2.0-green)](https://www.autohotkey.com/) [![License](https://img.shields.io/badge/License-GPL--3.0-orange)](license.txt)

## Features

- **Automatic Window Positioning:** Define rules for specific windows that are automatically applied
- **Flexible Matching:** Identify windows by title or class name
- **Maximize Support:** Option to maximize windows instead of setting specific dimensions
- **Hotkey Support:** Configurable keyboard shortcuts for quick window capture and rule application
- **System Tray Integration:** Runs quietly in the background with easy access via tray menu
- **Multi-Language Support:** Available in German and English (easily extendable)
- **Autostart Option:** Optionally start with Windows
- **Pause Function:** Temporarily disable all rules without closing the application

### Hidden Feature

- **Stay on Top:** Press `Ctrl+Win+Space` to toggle "Always on Top" for the active window

## Requirements

- Windows 7 or higher (64-bit)
- AutoHotkey v2.0 (only for running the .ahk script)

## Installation

1. Download the latest release
2. Extract to your preferred location
3. Run `AutoReSizer.exe` (or `AutoReSizer.ahk` if you have AutoHotkey v2 installed)

## Usage

### Creating Rules

1. Right-click the tray icon and select **"Capture Window"**
2. Select the window you want to create a rule for
3. Set the desired position (X, Y) and size (W, H)
4. Choose matching method (by class or title)
5. Click **"Add"** to save the rule

### Managing Rules

- Access **"Manage Rules"** from the tray menu
- Double-click a rule to edit it
- Toggle rules on/off without deleting them
- Delete rules you no longer need

### Hotkeys

Configure hotkeys in Settings:
- **Capture Window Hotkey:** Quickly capture the active window (Ctrl+Win+[Key])
- **Apply Rules Hotkey:** Manually apply all rules to open windows (Ctrl+Win+[Key])

## File Structure

```
AutoReSizer/
├── AutoReSizer.ahk      # Main script
├── AutoReSizer.exe      # Compiled executable
├── AutoReSizer.ini      # Configuration (rules, settings)
├── AutoReSizer.dll      # Icon resources
├── Deutsch.lng          # German language file
├── English.lng          # English language file
├── icons/icon.ico       # Application icon
├── license.txt          # GPL-3.0 License
└── readme.txt           # Documentation
```

## Adding Languages

1. Copy an existing `.lng` file (e.g., `English.lng`)
2. Rename it to your language (e.g., `French.lng`)
3. Translate all values (keep the keys unchanged)
4. Update the `[Info]` section with language details
5. Restart AutoReSizer and select the new language in Settings

## Changelog

### Version 1.6.1
- Rules are no longer applied in the background while the rules manager is open
- Hotkey capture now requires a modifier key (except F1–F12) — plain keys like a letter or Space can no longer be hijacked system-wide
- INI file is now stored as UTF-16: rule matches/names with special characters (e.g. •, →, emoji) no longer break silently
- Fixed a possible error dialog when closing Settings during a running hotkey capture
- Fixed swapped title/text in tray notifications; double-clicking an empty list area no longer opens the previously focused entry
- Windows reusing a recycled window handle are no longer skipped; AutoReSizer's own dialogs are excluded from rule matching
- **Performance:** no background window scan while no rules are active, active-window polling only runs while the capture hotkey is enabled
- More robustness: missing icon DLL no longer causes error cascades, quoted autostart path, no exit when language files are missing, English fallback on first run

### Version 1.6.0
- Fixed a crash when a position/size field (X/Y/W/H) was left empty in the rule dialogs
- Configurable hotkeys can no longer silently override the built-in **Stay on Top** hotkey (`Ctrl+Win+Space`)
- More robust against corrupted or manually edited INI files (no more start-up crash)
- Stopped silent endless retries on windows that cannot be moved (e.g. elevated processes)
- **Performance:** window class/title is now read once per window, reduced active-window polling, single summary notification per cycle
- X/Y fields now accept negative coordinates (multi-monitor setups)
- Fixed an icon-handle leak when opening dialogs repeatedly
- Hardened window capture against windows closing mid-action
- Internal refactoring, reduced code duplication, and additional localized strings

### Version 1.5.8
- Fixed tray icon ghosting after exit
- Added **Stay on Top** feature (`Ctrl+Win+Space`) - hidden feature
- Dialog icons now match their corresponding tray menu icons
- Updated tray icon to use application icon
- Removed hotkey hint from tray tooltip
- Various UI improvements

### Version 1.5.7
- Pause menu item now toggles between "Pause" and "Resume" with appropriate icons
- Tray icon changes to pause icon when paused
- Added `SetGuiIcon()` helper function for consistent window icons

### Version 1.5.6
- Added hotkey for applying all rules manually
- Improved rule matching and application

### Version 1.5.5
- Added tooltips for position/size fields
- UI refinements

### Version 1.5.0
- Complete rebuild with AutoHotkey v2
- New multi-language support system
- Improved settings dialog with multiple hotkey options

### Version 1.0.0
- Initial release
- Basic window positioning functionality
- System tray integration

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](license.txt) file for details.

## Credits

- **Author:** HJS
- **Contact:** autoresizer@gmx.com
- **GitHub:** https://github.com/HJS-cpu/AutoReSizer

---

*This is an independent implementation inspired by the concept of automatic window sizing. It is not related to or derived from any other software with a similar name.*
