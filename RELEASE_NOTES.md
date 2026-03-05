## AutoReSizer - Window Size/Position Manager

Automatic window management tool for Windows (AutoHotkey v2.0).

### Features
- **Automatic Window Positioning:** Define rules for specific windows that are applied automatically
- **Flexible Matching:** Identify windows by title or class name
- **Maximize Support:** Automatically maximize windows instead of setting specific dimensions
- **Hotkey Support:** Configurable hotkey for quick window capture
- **Multi-Language:** German and English included (easily extendable)
- **Autostart:** Optionally start with Windows
- **Stay on Top:** `Ctrl+Win+Space` toggles "Always on Top" for the active window (Hidden Feature)

### Changes in v1.5.9
- **Freely configurable hotkeys:** Full key combinations can now be chosen via capture dialog (no longer limited to Ctrl+Win+letter)
- Backward compatible: Existing single-letter hotkey settings are automatically migrated
- Code optimizations: Centralized window match logic, fixed INI orphaned sections cleanup
- ProcessedWindows memory leak fix (stale handles cleaned up periodically)
- Width/height validation for window rules (must be > 0)

### Installation
1. Download and extract the ZIP file
2. Run `AutoReSizer.exe`
3. Create rules via the tray menu

### Included Files
| File | Description |
|------|-------------|
| `AutoReSizer.exe` | Main application |
| `AutoReSizer.dll` | Icon resources |
| `Deutsch.lng` | German language file |
| `English.lng` | English language file |
| `readme.txt` | Documentation |
| `license.txt` | GPL-3.0 License |

### System Requirements
- Windows 7 or higher (64-bit)
