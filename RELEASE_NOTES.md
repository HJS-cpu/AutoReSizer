### Changes in v1.6.0
**Bug fixes**
- Fixed a crash when a position/size field (X/Y/W/H) was left empty in the rule dialogs
- The configurable hotkeys can no longer silently override the built-in StayOnTop hotkey (Ctrl+Win+Space)
- Robust against corrupted or manually edited INI files (no more start-up crash)
- Stopped silent endless retries on windows that cannot be moved (e.g. elevated processes)

**Performance**
- Window class/title is now read once per window instead of once per rule (faster background scan)
- Reduced active-window polling frequency
- Rule application now shows a single summary notification per cycle

**Robustness & usability**
- Fixed an icon-handle leak when opening dialogs repeatedly
- X/Y fields now accept negative coordinates (multi-monitor setups)
- Hardened window capture against windows closing mid-action

**Internal**
- Refactoring and reduced code duplication; additional localized strings

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
