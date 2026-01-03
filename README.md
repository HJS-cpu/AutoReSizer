# AutoReSizer

**AutoReSizer** ist ein modernes Window Management Tool für Windows, das Fenster automatisch in der gewünschten Größe und Position positioniert. Es ist die Neuauflage des klassischen AutoSizer-Konzepts, komplett neu entwickelt mit AutoHotkey v2.

![AutoReSizer Version](https://img.shields.io/badge/version-1.5.3-blue)
![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v2.0-green)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey)
![License](https://img.shields.io/badge/license-MIT-orange)

## 🎯 Features

- **Automatische Fensterpositionierung**: Definiere Regeln für bestimmte Fenster, die automatisch angewendet werden
- **Flexible Fenster-Erkennung**: Fenster können über Fenstertitel oder Fensterklasse identifiziert werden
- **Maximieren-Option**: Fenster können auch automatisch maximiert werden
- **Hotkey-Capture**: Erfasse Fensterinformationen schnell per Tastenkombination (konfigurierbar)
- **Fensterauswahl-Liste**: Wähle aus allen aktuell geöffneten Fenstern das gewünschte aus
- **Regel-Verwaltung**: Bearbeite, lösche oder deaktiviere Regeln einzeln
- **Globale Pause**: Pausiere alle Regeln temporär mit einem Klick
- **Persistente Speicherung**: Alle Einstellungen werden automatisch in einer INI-Datei gespeichert
- **Autostart-Option**: Starte AutoReSizer automatisch mit Windows
- **Mehrsprachig**: Unterstützung für Deutsch und Englisch (weitere Sprachen einfach hinzufügbar)
- **Kompaktes Design**: Schlanke, moderne Benutzeroberfläche

## 📋 Systemvoraussetzungen

- Windows 7 oder höher (64-Bit)
- [AutoHotkey v2.0](https://www.autohotkey.com/) (nur für .ahk Version)
- Für die .exe Version werden keine zusätzlichen Abhängigkeiten benötigt

## 🚀 Installation

### Variante 1: Kompilierte Version (.exe)
1. Lade die neueste `AutoReSizer.exe` von den [Releases](https://github.com/HJS-cpu/AutoReSizer/releases) herunter
2. Starte die Datei - fertig!

### Variante 2: AutoHotkey-Skript (.ahk)
1. Installiere [AutoHotkey v2.0](https://www.autohotkey.com/)
2. Lade `AutoReSizer.ahk` und die Sprachdateien herunter
3. Starte das Skript per Doppelklick

## 💡 Verwendung

### Erste Schritte

1. **AutoReSizer starten**: Das Programm läuft im Hintergrund und zeigt ein Tray-Icon
2. **Fenster erfassen**: 
   - Klicke im Tray-Menü auf "Fenster erfassen" oder nutze den konfigurierbaren Hotkey (Standard: Strg+Win+W)
   - Wähle das gewünschte Fenster aus der Liste
3. **Regel konfigurieren**:
   - Gib optional einen Namen für die Regel ein
   - Passe Position und Größe an oder aktiviere "Fenster maximieren"
   - Wähle die Erkennungsmethode (Klasse oder Titel)
4. **Regel speichern**: Klicke auf "Hinzufügen"

Die Regel wird ab sofort automatisch auf neue Fenster angewendet!

### Regelverwaltung

Über "Regeln verwalten" im Tray-Menü kannst du:
- Regeln bearbeiten (Doppelklick oder Button "Bearbeiten")
- Regeln temporär deaktivieren (Button "Umschalten")
- Regeln löschen (Button "Löschen")
- Alle Regeln pausieren/fortsetzen

### Einstellungen

- **Hotkey anpassen**: Ändere die Tastenkombination für die Fenstererfassung
- **Autostart**: Aktiviere den automatischen Start mit Windows
- **Sprache**: Wechsle zwischen Deutsch und Englisch

## 📂 Dateistruktur

```
AutoReSizer/
├── AutoReSizer.ahk         # Hauptskript
├── AutoReSizer.ini         # Konfigurationsdatei (automatisch erstellt)
├── German.lng              # Deutsche Sprachdatei
├── English.lng             # Englische Sprachdatei
├── Icons/
│   ├── active.ico          # Tray-Icon (aktiv)
│   └── paused.ico          # Tray-Icon (pausiert)
└── README.md               # Diese Datei
```

## 🌍 Sprachen

AutoReSizer unterstützt mehrere Sprachen durch .lng-Dateien:
- Deutsch (German.lng)
- Englisch (English.lng)

Weitere Sprachen können einfach durch Kopieren und Übersetzen einer bestehenden .lng-Datei hinzugefügt werden.

## 🔧 Technische Details

### Erkennungsmethoden
- **Nach Klasse**: Identifiziert Fenster anhand ihrer Windows-Klasse (zuverlässiger)
- **Nach Titel**: Identifiziert Fenster anhand des Fenstertitels (flexibler)

### Maximieren vs. Position/Größe
- Wenn "Fenster maximieren" aktiviert ist, werden die Positions- und Größenwerte ignoriert
- Andernfalls wird das Fenster exakt auf die angegebenen Koordinaten und Dimensionen gesetzt

### Persistente Speicherung
Alle Einstellungen werden in `AutoReSizer.ini` gespeichert:
- Regeln mit allen Parametern
- Hotkey-Konfiguration
- Autostart-Status
- Spracheinstellung

## 🐛 Bekannte Einschränkungen

- Fenster werden erst beim erstmaligen Erscheinen positioniert, nicht bei jedem Fokus-Wechsel
- Manche Fenster (z.B. mit Administratorrechten) können je nach UAC-Einstellungen nicht erfasst werden
- Die Regel-Anwendung erfolgt alle 500ms, daher kann es kurzzeitig zu sichtbarem "Springen" kommen

## 🤝 Beitragen

Contributions sind willkommen! Wenn du einen Fehler findest oder ein Feature vorschlagen möchtest:

1. Erstelle ein Issue
2. Forke das Repository
3. Erstelle einen Feature Branch (`git checkout -b feature/AmazingFeature`)
4. Committe deine Änderungen (`git commit -m 'Add some AmazingFeature'`)
5. Pushe zum Branch (`git push origin feature/AmazingFeature`)
6. Öffne einen Pull Request

## 📝 Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert - siehe die [LICENSE](LICENSE) Datei für Details.

## 👤 Autor

**HJS**

- GitHub: [@HJS-cpu](https://github.com/HJS-cpu)
- E-Mail: autoresizer@gmx.net

## 🙏 Danksagungen

- Inspiriert vom originalen AutoSizer Konzept
- Gebaut mit [AutoHotkey v2.0](https://www.autohotkey.com/)

## 📜 Changelog

### Version 1.5.3 (Aktuell)
- Kompaktes Design für alle Dialoge
- Optimierter Über-Dialog
- Verbesserte Benutzeroberfläche
- Bug-Fixes in der Regelverwaltung

### Version 1.5.0
- Mehrsprachigkeit (Deutsch/Englisch)
- Sprachauswahl beim ersten Start
- Vollständige Lokalisierung aller UI-Elemente

### Version 1.4.0
- Autostart-Funktion hinzugefügt
- Einstellungen-Dialog erweitert
- Registry-Integration für Windows-Start

### Version 1.3.0
- Regel-Verwaltung komplett überarbeitet
- Bearbeiten/Löschen/Umschalten von Regeln
- Globale Pause-Funktion
- Persistente Speicherung

### Version 1.2.0
- Fensterauswahl per Liste
- Konfigurierbare Hotkeys
- Maximieren-Option

### Version 1.0.0
- Erste öffentliche Version
- Grundlegende Window Management Funktionen
- Regelbasierte Fensterpositionierung

---

**Hinweis**: Dieses Tool wurde komplett neu entwickelt und ist nicht mit dem ursprünglichen AutoSizer von Jonathan Clark verwandt. Es handelt sich um eine eigenständige Neuimplementierung mit AutoHotkey v2.
