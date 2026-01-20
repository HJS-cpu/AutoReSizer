# AutoReSizer

A modern window management tool for Windows that automatically positions and resizes windows based on user-defined rules.

![AutoReSizer](https://img.shields.io/badge/Version-1.5.8-blue) ![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v2.0-green) ![License](https://img.shields.io/badge/License-GPL--3.0-orange)

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

### Version 1.5.8
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
