# AutoReSizer

## Projektübersicht
AutoReSizer ist ein Windows-Tool zur automatischen Verwaltung von Fensterpositionen und -größen. Geschrieben in **AutoHotkey v2.0**.

- **Version:** 1.5.8
- **Autor:** HJS
- **GitLab:** https://gitlab.com/HJS-cpu/autoresizer
- **Lizenz:** GPL-3.0

## Dateistruktur

```
AutoReSizer/
├── AutoReSizer.ahk      # Hauptskript (einzige Code-Datei)
├── AutoReSizer.dll      # Icon-Ressourcen
├── AutoReSizer.ini      # Konfiguration (Regeln, Einstellungen)
├── Deutsch.lng          # Deutsche Sprachdatei
├── English.lng          # Englische Sprachdatei
├── icons/icon.ico       # Anwendungs-Icon
├── license.txt          # GPL-3.0 Lizenz
├── readme.txt           # Dokumentation
└── README.md            # GitHub-Dokumentation
```

## Architektur

### Sprachsystem
- Lokalisierung über `.lng` Dateien (INI-Format)
- Schlüssel-Nummern nach Sektionen gruppiert:
  - `[General]` 100-199: Tray-Menü
  - `[About]` 200-299: Über-Dialog
  - `[Settings]` 300-399: Einstellungen
  - `[RulesManager]` 400-499: Regelverwaltung
  - `[CaptureWindow]` 500-599: Fenster erfassen
  - `[EditRule]` 600-699: Regel bearbeiten
  - `[WindowPicker]` 700-799: Fensterauswahl
  - `[LanguageSelect]` 800-899: Sprachauswahl
  - `[Messages]` 900-999: Meldungen/TrayTips
- Funktion `L(section, key)` liefert übersetzte Strings

### ToolTip-System
- `ToolTipControls` Map speichert Hwnd → ToolTip-Text
- `OnMouseMove` Handler zeigt ToolTips bei Hover
- Text-Controls brauchen `+0x100` Style (SS_NOTIFY) für Maus-Events

### Wichtige GUI-Dialoge
- **Fenster erfassen** (`ShowCaptureDialog`): Neues Fenster als Regel erfassen
- **Regel bearbeiten** (`EditRule`): Bestehende Regel anpassen
- **Regeln verwalten** (`ShowRulesManager`): ListView aller Regeln

### Regel-Matching
- Per **Klasse** (exakt) oder **Titel** (enthält)
- Regeln können Fenster maximieren oder auf X/Y/W/H setzen

### StayOnTop (Hidden Feature)
- Hotkey `Strg+Win+Space` togglet AlwaysOnTop für aktives Fenster
- `ToggleStayOnTop()` prüft ExStyle auf `WS_EX_TOPMOST` (0x8)
- SplashScreen-Feedback via `ShowStayOnTopSplash()` (verschwindet nach 1 Sek.)

### Icon-Zuordnung (AutoReSizer.dll)
| Icon | Verwendung |
|------|------------|
| 1 | About-Dialog, Tray-Menü "Über" |
| 2 | Einstellungen-Dialog, Tray-Menü "Einstellungen" |
| 3 | Tray-Menü "Beenden" |
| 4 | Pause-Icon (Tray + Menü) |
| 5 | Fenster erfassen/auswählen |
| 6 | Regeln verwalten/bearbeiten |
| 7 | Tray-Menü "Fortsetzen" |
| 8 | Tray-Icon (aktiv), Sprachauswahl |

## Coding-Konventionen

- Deutsche Kommentare im Code
- GUI-Elemente als globale Variablen (`MyGui`, `MyEdX`, etc.)
- Einheitliche Abstände in Dialogen (z.B. Label zu Edit: 18px)
- Buttons zentriert, je 100px breit mit 5px Abstand

## Letzte Änderungen

### Version 1.5.8
- **Tray-Icon Ghosting Fix:** `OnExit`-Callback mit `A_IconHidden := true` verhindert Geister-Icons im Systray nach Beenden
- **StayOnTop (Hidden Feature):** `Strg+Win+Space` togglet "Immer im Vordergrund" für das aktive Fenster
- SplashScreen-Feedback für StayOnTop (zentriert, verschwindet nach 1 Sekunde)
- Neue Sprachschlüssel `Messages-948/949` für StayOnTop-Meldungen
- Dialog-Icons entsprechen jetzt den Tray-Menü-Icons:
  - About: Icon 1
  - Einstellungen: Icon 2
  - Fenster erfassen/auswählen: Icon 5
  - Regeln verwalten/bearbeiten: Icon 6
- Tray-Icon (aktiv) verwendet jetzt AutoReSizer.dll Icon 8
- Hotkey-Hinweis aus Tray-Tooltip entfernt
- AutoReSizer.dll Version Info auf 1.5.8 aktualisiert

### Version 1.5.7
- Pause-Menüeintrag togglet jetzt zwischen "Pause" (Icon 4) und "Fortsetzen" (Icon 7)
- Neuer Sprachschlüssel `General-111` für "Fortsetzen"/"Resume"
- Tray-Icon zeigt bei Pause das Pause-Icon (AutoReSizer.dll, 4)
- Neue Hilfsfunktion `SetGuiIcon()` zum Setzen von DLL-Icons per Windows-API
