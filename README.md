# AutoReSizer

**AutoReSizer** is a modern window management tool for Windows that automatically positions windows in the desired size and position. It is the reimagined version of the classic AutoSizer concept, completely rebuilt with AutoHotkey v2.

![AutoReSizer Version](https://img.shields.io/badge/version-1.5.6-blue)
![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v2.0-green)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey)
![License](https://img.shields.io/badge/license-GPL--3.0-orange)

## 🎯 Features

- **Automatic Window Positioning**: Define rules for specific windows that are applied automatically
- **Flexible Window Detection**: Windows can be identified by window title or window class
- **Maximize Option**: Windows can also be automatically maximized
- **Hotkey Capture**: Capture window information quickly via keyboard shortcut (configurable)
- **Window Selection List**: Select from all currently open windows
- **Rule Management**: Edit, delete or disable rules individually
- **Global Pause**: Pause all rules temporarily with one click
- **Persistent Storage**: All settings are automatically saved in an INI file
- **Autostart Option**: Start AutoReSizer automatically with Windows
- **Multi-language**: Support for German and English (additional languages easily added)
- **Compact Design**: Sleek, modern user interface

## 📋 System Requirements

- Windows 7 or higher (64-bit)
- [AutoHotkey v2.0](https://www.autohotkey.com/) (only for .ahk version)
- No additional dependencies required for the .exe version

## 🚀 Installation

### Option 1: Compiled Version (.exe)
1. Download the latest `AutoReSizer.exe` from the [Releases](https://github.com/HJS-cpu/AutoReSizer/releases)
2. Run the file - done!

### Option 2: AutoHotkey Script (.ahk)
1. Install [AutoHotkey v2.0](https://www.autohotkey.com/)
2. Download `AutoReSizer.ahk` and the language files
3. Start the script by double-clicking

## 💡 Usage

### Getting Started

1. **Start AutoReSizer**: The program runs in the background and shows a tray icon
2. **Capture Window**: 
   - Click "Capture Window" in the tray menu or use the configurable hotkey (default: Ctrl+Win+W)
   - Select the desired window from the list
3. **Configure Rule**:
   - Optionally enter a name for the rule
   - Adjust position and size or enable "Maximize Window"
   - Choose the detection method (Class or Title)
4. **Save Rule**: Click "Add"

The rule will now be automatically applied to new windows!

### Rule Management

Via "Manage Rules" in the tray menu you can:
- Edit rules (double-click or "Edit" button)
- Temporarily disable rules ("Toggle" button)
- Delete rules ("Delete" button)
- Pause/resume all rules

### Settings

- **Customize Hotkey**: Change the keyboard shortcut for window capture
- **Autostart**: Enable automatic start with Windows
- **Language**: Switch between German and English

## 📂 File Structure

```
AutoReSizer/
├── AutoReSizer.ahk         # Main script
├── AutoReSizer.ini         # Configuration file (automatically created)
├── German.lng              # German language file
├── English.lng             # English language file
├── readme.txt              # Readme file
├── license.txt             # GPL-3.0 License
├── Icons/
│   ├── active.ico          # Tray icon (active)
│   └── paused.ico          # Tray icon (paused)
└── README.md               # This file
```

## 🌍 Languages

AutoReSizer supports multiple languages through .lng files:
- German (German.lng)
- English (English.lng)

Additional languages can be easily added by copying and translating an existing .lng file.

## 🔧 Technical Details

### Detection Methods
- **By Class**: Identifies windows by their Windows class (more reliable)
- **By Title**: Identifies windows by their window title (more flexible)

### Maximize vs. Position/Size
- If "Maximize Window" is enabled, position and size values are ignored
- Otherwise, the window is set exactly to the specified coordinates and dimensions

### Persistent Storage
All settings are saved in `AutoReSizer.ini`:
- Rules with all parameters
- Hotkey configuration
- Autostart status
- Language setting

## 🐛 Known Limitations

- Windows are positioned only when they first appear, not on every focus change
- Some windows (e.g., with administrator rights) may not be captured depending on UAC settings
- Rule application occurs every 500ms, so brief visible "jumping" may occur

## 🤝 Contributing

Contributions are welcome! If you find a bug or want to suggest a feature:

1. Create an issue
2. Fork the repository
3. Create a feature branch (`git checkout -b feature/AmazingFeature`)
4. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
5. Push to the branch (`git push origin feature/AmazingFeature`)
6. Open a pull request

## 📝 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**HJS**

- GitHub: [@HJS-cpu](https://github.com/HJS-cpu)
- E-Mail: autoresizer@gmx.net

## 🙏 Acknowledgments

- Inspired by the original AutoSizer concept
- Built with [AutoHotkey v2.0](https://www.autohotkey.com/)

## 📜 Changelog

### Version 1.5.6 (Current)
- Centered buttons in all dialogs for improved UI consistency
- All buttons in Rules Manager now have equal width
- Renamed "Pause All" to "Pause" for better button fit
- Updated language files

### Version 1.5.4
- Fixed rules list refresh when Rules Manager window is already open
- Rules added via hotkey capture now immediately appear in open Rules Manager
- Improved window state synchronization

### Version 1.5.3
- Compact design for all dialogs
- Optimized About dialog
- Improved user interface
- Bug fixes in rule management

### Version 1.5.0
- Multi-language support (German/English)
- Language selection on first start
- Complete localization of all UI elements

### Version 1.4.0
- Autostart function added
- Settings dialog extended
- Registry integration for Windows startup

### Version 1.3.0
- Rule management completely redesigned
- Edit/delete/toggle rules
- Global pause function
- Persistent storage

### Version 1.2.0
- Window selection via list
- Configurable hotkeys
- Maximize option

### Version 1.0.0
- First public release
- Basic window management functions
- Rule-based window positioning

---

**Note**: This tool was completely rebuilt from scratch and is not related to the original AutoSizer by Jonathan Clark. It is an independent reimplementation using AutoHotkey v2.
