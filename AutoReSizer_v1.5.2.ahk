#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ============================================================
; AutoReSizer - Window Size/Position Manager
; Version: 1.5.2 - UI Harmonisierung + ToolTips
; ============================================================

global AppName := "AutoReSizer"
global AppVersion := "1.5.2"
global AppAuthor := "HJS"
global AppGitHub := "https://github.com/HJS-cpu/AutoReSizer"
global AppEmail := "autoresizer@gmx.net"

global WindowRules := []
global ProcessedWindows := Map()
global LastActiveWindow := 0
global GlobalPaused := false

global CaptureHwnd := 0
global CaptureClass := ""
global CaptureTitle := ""
global MyGui := ""
global MyEdX := ""
global MyEdY := ""
global MyEdW := ""
global MyEdH := ""
global MyMatchDDL := ""
global MyMaximizeChk := ""
global MyRuleName := ""
global MyEnabledChk := ""
global EditingRuleIndex := 0

global RulesManagerGui := ""
global RulesListView := ""
global BtnEdit := ""
global BtnToggle := ""
global BtnDelete := ""

global WindowPickerGui := ""
global SettingsGui := ""
global AboutGui := ""
global LanguageGui := ""

; Hotkey-Einstellungen
global HotkeyEnabled := false
global HotkeyKey := ""
global CurrentHotkey := ""

; Autostart
global AutostartEnabled := false
global AutostartRegKey := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"

; Lokalisierung
global CurrentLanguage := ""
global LangStrings := Map()

; ToolTip-Handling
global ToolTipControls := Map()
OnMessage(0x200, OnMouseMove)  ; WM_MOUSEMOVE

global IniFile := A_ScriptDir "\AutoReSizer.ini"

; Sprache zuerst laden
LoadLanguageSetting()
if (CurrentLanguage = "" || !FileExist(A_ScriptDir "\" CurrentLanguage ".lng")) {
    ShowLanguageSelect(true)
} else {
    LoadLanguageFile(CurrentLanguage)
}

LoadRules()
LoadSettings()
RegisterHotkey()

; --- Tray-Icon Setup ---
UpdateTrayIcon()
BuildTrayMenu()

SetTimer(CheckWindows, 500)
SetTimer(TrackActiveWindow, 250)

; ============================================================
; ToolTip bei Mouse-Hover über Controls
; ============================================================
OnMouseMove(wParam, lParam, msg, hwnd) {
    global ToolTipControls
    static lastHwnd := 0
    static lastTime := 0
    
    ; Nur alle 100ms prüfen für Performance
    if (A_TickCount - lastTime < 100)
        return
    lastTime := A_TickCount
    
    if (ToolTipControls.Has(hwnd)) {
        if (lastHwnd != hwnd) {
            ToolTip(ToolTipControls[hwnd])
            lastHwnd := hwnd
        }
    } else {
        if (lastHwnd != 0) {
            ToolTip()
            lastHwnd := 0
        }
    }
}

; ============================================================
; Sprach-Funktionen
; ============================================================
L(section, key) {
    global LangStrings
    fullKey := section "-" key
    if (LangStrings.Has(fullKey))
        return LangStrings[fullKey]
    return "???" fullKey "???"
}

; ============================================================
LoadLanguageSetting() {
    global IniFile, CurrentLanguage
    
    if (!FileExist(IniFile)) {
        CurrentLanguage := ""
        return
    }
    
    CurrentLanguage := IniRead(IniFile, "Settings", "Language", "")
}

; ============================================================
SaveLanguageSetting() {
    global IniFile, CurrentLanguage
    IniWrite(CurrentLanguage, IniFile, "Settings", "Language")
}

; ============================================================
LoadLanguageFile(langName) {
    global LangStrings, CurrentLanguage
    
    langFile := A_ScriptDir "\" langName ".lng"
    if (!FileExist(langFile))
        return false
    
    LangStrings := Map()
    CurrentLanguage := langName
    
    currentSection := ""
    
    Loop Read, langFile {
        line := Trim(A_LoopReadLine)
        
        ; Leere Zeilen und Kommentare überspringen
        if (line = "" || SubStr(line, 1, 1) = ";")
            continue
        
        ; Sektion erkennen
        if (SubStr(line, 1, 1) = "[" && SubStr(line, -1) = "]") {
            currentSection := SubStr(line, 2, -1)
            continue
        }
        
        ; Key=Value parsen
        if (currentSection != "" && InStr(line, "=")) {
            pos := InStr(line, "=")
            key := Trim(SubStr(line, 1, pos - 1))
            value := Trim(SubStr(line, pos + 1))
            fullKey := currentSection "-" key
            LangStrings[fullKey] := value
        }
    }
    
    return true
}

; ============================================================
GetAvailableLanguages() {
    languages := []
    
    Loop Files, A_ScriptDir "\*.lng" {
        langName := SubStr(A_LoopFileName, 1, -4)  ; .lng entfernen
        
        ; Sprachname aus Datei lesen
        try {
            displayName := IniRead(A_LoopFilePath, "Info", "LanguageName", langName)
            languages.Push({file: langName, name: displayName})
        } catch {
            languages.Push({file: langName, name: langName})
        }
    }
    
    return languages
}

; ============================================================
ShowLanguageSelect(isFirstRun := false) {
    global LanguageGui, CurrentLanguage, AppName
    
    if (IsGuiVisible(LanguageGui)) {
        WinActivate("ahk_id " LanguageGui.Hwnd)
        return
    }
    
    languages := GetAvailableLanguages()
    
    if (languages.Length = 0) {
        MsgBox("No language files (.lng) found! / Keine Sprachdateien (.lng) gefunden!", "Error / Fehler", "Icon! 4096")
        ExitApp()
    }
    
    ; Bei erstem Start nur AppName, sonst lokalisiert
    if (isFirstRun) {
        titleText := AppName
        promptText := ""
        okText := "OK"
        cancelText := ""
    } else {
        titleText := AppName " - " L("LanguageSelect", "800")
        promptText := L("LanguageSelect", "805")
        okText := L("LanguageSelect", "810")
        cancelText := L("LanguageSelect", "815")
    }
    
    LanguageGui := Gui("+AlwaysOnTop", titleText)
    LanguageGui.SetFont("s10")
    
    if (promptText != "")
        LanguageGui.Add("Text", "w300", promptText)
    
    ; Sprachliste erstellen
    langListBox := LanguageGui.Add("ListBox", "w300 h150 vLangSelect")
    
    selectedIndex := 1
    for i, lang in languages {
        langListBox.Add([lang.name])
        if (lang.file = CurrentLanguage)
            selectedIndex := i
    }
    langListBox.Choose(selectedIndex)
    
    ; Buttons zentriert
    if (!isFirstRun) {
        LanguageGui.Add("Button", "x55 w100", okText).OnEvent("Click", (*) => ApplyLanguageSelection(languages, isFirstRun))
        LanguageGui.Add("Button", "x+10 w100", cancelText).OnEvent("Click", (*) => CloseLanguageSelect())
        LanguageGui.OnEvent("Close", (*) => CloseLanguageSelect())
    } else {
        LanguageGui.Add("Button", "x110 w100", okText).OnEvent("Click", (*) => ApplyLanguageSelection(languages, isFirstRun))
        LanguageGui.OnEvent("Close", (*) => ExitApp())
    }
    
    LanguageGui.Show()
}

; ============================================================
ApplyLanguageSelection(languages, isFirstRun) {
    global LanguageGui, CurrentLanguage, AppName
    
    selected := LanguageGui["LangSelect"].Value
    if (selected = 0)
        selected := 1
    
    selectedLang := languages[selected]
    
    LanguageGui.Destroy()
    LanguageGui := ""
    
    LoadLanguageFile(selectedLang.file)
    SaveLanguageSetting()
    
    ; Tray-Menü neu aufbauen
    BuildTrayMenu()
    UpdateTrayIcon()
    
    if (!isFirstRun) {
        TrayTip(AppName, "Sprache geändert / Language changed", 1)
    }
}

; ============================================================
CloseLanguageSelect() {
    global LanguageGui
    LanguageGui.Destroy()
    LanguageGui := ""
}

; ============================================================
; Tray-Menü aufbauen
; ============================================================
BuildTrayMenu() {
    global AppName, AppVersion
    
    TrayMenu := A_TrayMenu
    TrayMenu.Delete()
    TrayMenu.Add(AppName " v" AppVersion, ShowAbout)
    TrayMenu.Add()
    TrayMenu.Add(L("General", "100"), ShowRulesManager)
    TrayMenu.Add(L("General", "105"), ShowWindowPicker)
    TrayMenu.Add()
    TrayMenu.Add(L("General", "110"), ToggleGlobalPause)
    TrayMenu.Add()
    TrayMenu.Add(L("General", "115"), ShowSettings)
    TrayMenu.Add()
    TrayMenu.Add(L("General", "120"), (*) => ExitApp())
    
    A_TrayMenu.Default := L("General", "100")
    
    UpdatePauseMenu()
}

; ============================================================
; Über-Dialog anzeigen
; ============================================================
ShowAbout(*) {
    global AboutGui, AppName, AppVersion, AppAuthor, AppGitHub, AppEmail
    
    if (IsGuiVisible(AboutGui)) {
        WinActivate("ahk_id " AboutGui.Hwnd)
        return
    }
    
    AboutGui := Gui("+AlwaysOnTop", L("About", "200") " " AppName)
    AboutGui.SetFont("s12 bold")
    AboutGui.Add("Text", "w300 Center", AppName)
    
    AboutGui.SetFont("s10 norm")
    AboutGui.Add("Text", "w300 Center", L("About", "205") " " AppVersion)
    AboutGui.Add("Text", "w300 Center yp+25", L("About", "210") " " AppAuthor)
    
    AboutGui.Add("Text", "w300 Center yp+35", L("About", "215"))
    AboutGui.SetFont("s10 underline cBlue")
    AboutGui.Add("Text", "w300 Center yp+20 vGitHubLink", AppGitHub)
    AboutGui["GitHubLink"].OnEvent("Click", (*) => Run(AppGitHub))
    
    AboutGui.SetFont("s10 norm")
    AboutGui.Add("Text", "w300 Center yp+30", L("About", "220"))
    AboutGui.SetFont("s10 underline cBlue")
    AboutGui.Add("Text", "w300 Center yp+20 vEmailLink", AppEmail)
    AboutGui["EmailLink"].OnEvent("Click", (*) => Run("mailto:" AppEmail))
    
    AboutGui.SetFont("s10 norm")
    AboutGui.Add("Button", "w100 yp+40 x110", L("About", "225")).OnEvent("Click", (*) => CloseAbout())
    AboutGui.OnEvent("Close", (*) => CloseAbout())
    
    AboutGui.Show()
}

; ============================================================
CloseAbout() {
    global AboutGui
    AboutGui.Destroy()
    AboutGui := ""
}

; ============================================================
; Einstellungen laden
; ============================================================
LoadSettings() {
    global IniFile, HotkeyEnabled, HotkeyKey, AutostartEnabled
    
    if (!FileExist(IniFile))
        return
    
    HotkeyEnabled := IniRead(IniFile, "Settings", "HotkeyEnabled", "0") = "1"
    HotkeyKey := IniRead(IniFile, "Settings", "HotkeyKey", "")
    
    AutostartEnabled := CheckAutostart()
}

; ============================================================
; Einstellungen speichern
; ============================================================
SaveSettings() {
    global IniFile, HotkeyEnabled, HotkeyKey
    
    IniWrite(HotkeyEnabled ? "1" : "0", IniFile, "Settings", "HotkeyEnabled")
    IniWrite(HotkeyKey, IniFile, "Settings", "HotkeyKey")
}

; ============================================================
; Autostart prüfen
; ============================================================
CheckAutostart() {
    global AutostartRegKey, AppName
    
    try {
        regValue := RegRead(AutostartRegKey, AppName)
        return (regValue != "")
    } catch {
        return false
    }
}

; ============================================================
; Autostart setzen/entfernen
; ============================================================
SetAutostart(enable) {
    global AutostartRegKey, AppName, AutostartEnabled
    
    if (enable) {
        try {
            RegWrite(A_ScriptFullPath, "REG_SZ", AutostartRegKey, AppName)
            AutostartEnabled := true
            return true
        } catch as err {
            MsgBox("Autostart error: " err.Message, L("Messages", "995"), "Icon! 4096")
            return false
        }
    } else {
        try {
            RegDelete(AutostartRegKey, AppName)
            AutostartEnabled := false
            return true
        } catch {
            AutostartEnabled := false
            return true
        }
    }
}

; ============================================================
; Hotkey registrieren/deregistrieren
; ============================================================
RegisterHotkey() {
    global HotkeyEnabled, HotkeyKey, CurrentHotkey
    
    if (CurrentHotkey != "") {
        try {
            Hotkey(CurrentHotkey, "Off")
        }
        CurrentHotkey := ""
    }
    
    if (HotkeyEnabled && HotkeyKey != "") {
        try {
            newHotkey := "^#" HotkeyKey
            Hotkey(newHotkey, (*) => CaptureWindow())
            CurrentHotkey := newHotkey
        } catch as err {
            MsgBox("Hotkey error: " err.Message, L("Messages", "995"), "Icon! 4096")
        }
    }
    
    UpdateTrayIcon()
}

; ============================================================
; Prüfen ob GUI existiert und sichtbar ist
; ============================================================
IsGuiVisible(guiVar) {
    if (!IsObject(guiVar))
        return false
    try {
        WinExist("ahk_id " guiVar.Hwnd)
        return true
    } catch {
        return false
    }
}

; ============================================================
; Alle Dialoge schließen
; ============================================================
CloseAllDialogs() {
    global MyGui, RulesManagerGui, WindowPickerGui, SettingsGui, AboutGui, LanguageGui
    
    try {
        if (IsGuiVisible(MyGui))
            MyGui.Destroy()
    }
    try {
        if (IsGuiVisible(RulesManagerGui))
            RulesManagerGui.Destroy()
    }
    try {
        if (IsGuiVisible(WindowPickerGui))
            WindowPickerGui.Destroy()
    }
    try {
        if (IsGuiVisible(SettingsGui))
            SettingsGui.Destroy()
    }
    try {
        if (IsGuiVisible(AboutGui))
            AboutGui.Destroy()
    }
    try {
        if (IsGuiVisible(LanguageGui))
            LanguageGui.Destroy()
    }
    
    MyGui := ""
    RulesManagerGui := ""
    WindowPickerGui := ""
    SettingsGui := ""
    AboutGui := ""
    LanguageGui := ""
}

; ============================================================
ToggleGlobalPause(*) {
    global GlobalPaused, AppName
    
    GlobalPaused := !GlobalPaused
    UpdateTrayIcon()
    UpdatePauseMenu()
    
    if (GlobalPaused) {
        TrayTip(AppName, L("Messages", "900"), 1)
    } else {
        global ProcessedWindows := Map()
        TrayTip(AppName, L("Messages", "905"), 1)
    }
}

; ============================================================
UpdatePauseMenu() {
    global GlobalPaused
    
    if (GlobalPaused)
        A_TrayMenu.Check(L("General", "110"))
    else
        A_TrayMenu.Uncheck(L("General", "110"))
}

; ============================================================
UpdateTrayIcon() {
    global GlobalPaused, HotkeyEnabled, HotkeyKey, AppName
    
    if (GlobalPaused) {
        TraySetIcon("Shell32.dll", 110)
        A_IconTip := AppName " - " L("General", "130")
    } else {
        TraySetIcon("Shell32.dll", 16)
        hotkeyText := ""
        if (HotkeyEnabled && HotkeyKey != "")
            hotkeyText := " (Ctrl+Win+" HotkeyKey ")"
        A_IconTip := AppName " - " L("General", "125") hotkeyText
    }
}

; ============================================================
; Einstellungen Dialog
; ============================================================
ShowSettings(*) {
    global SettingsGui, HotkeyEnabled, HotkeyKey, AutostartEnabled, AppName
    global SettingsHotkeyEdit, SettingsHotkeyChk, SettingsAutostartChk
    
    if (IsGuiVisible(SettingsGui)) {
        WinActivate("ahk_id " SettingsGui.Hwnd)
        return
    }
    
    AutostartEnabled := CheckAutostart()
    
    SettingsGui := Gui("+AlwaysOnTop", AppName " - " L("Settings", "300"))
    SettingsGui.SetFont("s10")
    
    ; Hotkey Bereich
    SettingsGui.Add("GroupBox", "w350 h120", L("Settings", "305"))
    
    SettingsHotkeyChk := SettingsGui.Add("Checkbox", "xp+10 yp+25", L("Settings", "310"))
    SettingsHotkeyChk.Value := HotkeyEnabled
    SettingsHotkeyChk.OnEvent("Click", OnHotkeyToggle)
    
    SettingsGui.Add("Text", "x20 yp+35", L("Settings", "315"))
    SettingsHotkeyEdit := SettingsGui.Add("Edit", "x110 yp-3 w50 Uppercase Limit1 Center", HotkeyKey)
    SettingsHotkeyEdit.Enabled := HotkeyEnabled
    
    SettingsGui.Add("Text", "x170 yp+3 cGray", L("Settings", "320"))
    
    SettingsGui.Add("Text", "x20 yp+30 cGray w320", L("Settings", "325"))
    
    ; Autostart Bereich
    SettingsGui.Add("GroupBox", "x10 yp+40 w350 h60", L("Settings", "330"))
    
    SettingsAutostartChk := SettingsGui.Add("Checkbox", "xp+10 yp+25", L("Settings", "335"))
    SettingsAutostartChk.Value := AutostartEnabled
    
    ; Sprache Bereich
    SettingsGui.Add("GroupBox", "x10 yp+45 w350 h60", L("Settings", "350"))
    
    SettingsGui.Add("Button", "xp+10 yp+22 w150", L("Settings", "355")).OnEvent("Click", (*) => OpenLanguageFromSettings())
    
    ; Buttons zentriert
    SettingsGui.Add("Button", "x80 yp+55 w100", L("Settings", "340")).OnEvent("Click", SaveSettingsAndClose)
    SettingsGui.Add("Button", "x+10 w100", L("Settings", "345")).OnEvent("Click", (*) => CloseSettings())
    SettingsGui.OnEvent("Close", (*) => CloseSettings())
    
    SettingsGui.Show()
}

; ============================================================
OpenLanguageFromSettings() {
    global SettingsGui
    SettingsGui.Destroy()
    SettingsGui := ""
    ShowLanguageSelect(false)
}

; ============================================================
OnHotkeyToggle(*) {
    global SettingsHotkeyEdit, SettingsHotkeyChk
    
    SettingsHotkeyEdit.Enabled := SettingsHotkeyChk.Value
}

; ============================================================
SaveSettingsAndClose(*) {
    global SettingsGui, SettingsHotkeyEdit, SettingsHotkeyChk, SettingsAutostartChk
    global HotkeyEnabled, HotkeyKey, AppName
    
    newKey := SettingsHotkeyEdit.Value
    newEnabled := SettingsHotkeyChk.Value
    newAutostart := SettingsAutostartChk.Value
    
    if (newEnabled && newKey != "") {
        if (!RegExMatch(newKey, "^[A-Z0-9]$")) {
            MsgBox(L("Messages", "985"), L("Messages", "980"), "Icon! 4096")
            return
        }
    }
    
    HotkeyEnabled := newEnabled
    HotkeyKey := newKey
    
    SaveSettings()
    RegisterHotkey()
    SetAutostart(newAutostart)
    
    SettingsGui.Destroy()
    SettingsGui := ""
    
    if (HotkeyEnabled && HotkeyKey != "")
        TrayTip(AppName, L("Messages", "910") " Ctrl+Win+" HotkeyKey, 1)
}

; ============================================================
CloseSettings() {
    global SettingsGui
    SettingsGui.Destroy()
    SettingsGui := ""
}

; ============================================================
LoadRules() {
    global WindowRules, IniFile
    
    WindowRules := []
    
    if (!FileExist(IniFile))
        return
    
    ruleCount := IniRead(IniFile, "General", "RuleCount", "0")
    ruleCount := Integer(ruleCount)
    
    Loop ruleCount {
        section := "Rule" A_Index
        
        match := IniRead(IniFile, section, "Match", "")
        if (match = "")
            continue
        
        ruleName := IniRead(IniFile, section, "Name", "")
        matchType := IniRead(IniFile, section, "MatchType", "class")
        maximize := IniRead(IniFile, section, "Maximize", "0")
        enabled := IniRead(IniFile, section, "Enabled", "1")
        x := Integer(IniRead(IniFile, section, "X", "0"))
        y := Integer(IniRead(IniFile, section, "Y", "0"))
        w := Integer(IniRead(IniFile, section, "W", "800"))
        h := Integer(IniRead(IniFile, section, "H", "600"))
        
        WindowRules.Push({
            name: ruleName,
            match: match,
            matchType: matchType,
            maximize: (maximize = "1"),
            enabled: (enabled = "1"),
            x: x,
            y: y,
            w: w,
            h: h
        })
    }
}

; ============================================================
SaveRules() {
    global WindowRules, IniFile
    
    ruleCount := WindowRules.Length
    
    Loop {
        section := "Rule" A_Index
        try {
            test := IniRead(IniFile, section, "Match", "")
            if (test = "")
                break
            IniDelete(IniFile, section)
        } catch {
            break
        }
    }
    
    IniWrite(ruleCount, IniFile, "General", "RuleCount")
    
    for i, rule in WindowRules {
        section := "Rule" i
        IniWrite(rule.name, IniFile, section, "Name")
        IniWrite(rule.match, IniFile, section, "Match")
        IniWrite(rule.matchType, IniFile, section, "MatchType")
        IniWrite(rule.maximize ? "1" : "0", IniFile, section, "Maximize")
        IniWrite(rule.enabled ? "1" : "0", IniFile, section, "Enabled")
        IniWrite(rule.x, IniFile, section, "X")
        IniWrite(rule.y, IniFile, section, "Y")
        IniWrite(rule.w, IniFile, section, "W")
        IniWrite(rule.h, IniFile, section, "H")
    }
}

; ============================================================
GetRuleDisplayName(rule) {
    if (rule.name != "")
        return rule.name
    return rule.match
}

; ============================================================
TrackActiveWindow() {
    global LastActiveWindow
    try {
        hwnd := WinGetID("A")
        if (hwnd) {
            wclass := WinGetClass(hwnd)
            if (wclass != "Shell_TrayWnd" && wclass != "AutoHotkeyGUI")
                LastActiveWindow := hwnd
        }
    }
}

; ============================================================
; Regelverwaltung - ListView
; ============================================================
ShowRulesManager(*) {
    global WindowRules, GlobalPaused, AppName
    global RulesManagerGui, RulesListView, BtnEdit, BtnToggle, BtnDelete
    
    if (IsGuiVisible(RulesManagerGui)) {
        WinActivate("ahk_id " RulesManagerGui.Hwnd)
        return
    }
    
    CloseAllDialogs()
    
    BtnEdit := ""
    BtnToggle := ""
    BtnDelete := ""
    
    SetTimer(CheckWindows, 0)
    
    RulesManagerGui := Gui("+AlwaysOnTop", AppName " - " L("RulesManager", "400"))
    RulesManagerGui.SetFont("s10")
    
    statusText := GlobalPaused ? "⚠️ " L("General", "130") : "✓ " L("General", "125")
    RulesManagerGui.Add("Text", "w700 vGlobalStatus", L("RulesManager", "405") " " statusText)
    
    RulesManagerGui.Add("Text", , L("RulesManager", "410"))
    
    RulesListView := RulesManagerGui.Add("ListView", "w700 h300 vRulesLV", [
        L("RulesManager", "415"),
        L("RulesManager", "420"),
        L("RulesManager", "425"),
        L("RulesManager", "430"),
        L("RulesManager", "435"),
        "X", "Y", "W", "H"
    ])
    RulesListView.OnEvent("DoubleClick", EditRuleFromList)
    RulesListView.OnEvent("ItemSelect", OnRuleSelect)
    
    RulesListView.ModifyCol(1, "45 Center")
    RulesListView.ModifyCol(2, 120)
    RulesListView.ModifyCol(3, 150)
    RulesListView.ModifyCol(4, 55)
    RulesListView.ModifyCol(5, 40)
    RulesListView.ModifyCol(6, 50)
    RulesListView.ModifyCol(7, 50)
    RulesListView.ModifyCol(8, 50)
    RulesListView.ModifyCol(9, 50)
    
    ; Buttons mit gleichem Abstand (w100, Abstand 10px zwischen allen)
    RulesManagerGui.Add("Button", "x10 w100", L("RulesManager", "440")).OnEvent("Click", NewRuleFromManager)
    BtnEdit := RulesManagerGui.Add("Button", "x120 yp w100 Disabled", L("RulesManager", "445"))
    BtnEdit.OnEvent("Click", EditRuleFromList)
    BtnToggle := RulesManagerGui.Add("Button", "x230 yp w100 Disabled", L("RulesManager", "450"))
    BtnToggle.OnEvent("Click", ToggleRuleFromList)
    BtnDelete := RulesManagerGui.Add("Button", "x340 yp w100 Disabled", L("RulesManager", "455"))
    BtnDelete.OnEvent("Click", DeleteRuleFromList)
    pauseBtnText := GlobalPaused ? L("RulesManager", "460") : L("RulesManager", "465")
    RulesManagerGui.Add("Button", "x450 yp w130", pauseBtnText).OnEvent("Click", (*) => ToggleGlobalFromManager())
    RulesManagerGui.Add("Button", "x590 yp w100", L("RulesManager", "470")).OnEvent("Click", (*) => CloseRulesManager())
    RulesManagerGui.OnEvent("Close", (*) => CloseRulesManager())
    
    RefreshRulesList()
    
    RulesManagerGui.Show()
}

; ============================================================
RefreshRulesList() {
    global WindowRules, RulesListView
    
    RulesListView.Delete()
    
    for rule in WindowRules {
        activeText := rule.enabled ? "✓" : "✗"
        displayName := (rule.name != "") ? rule.name : L("RulesManager", "475")
        maxText := rule.maximize ? L("RulesManager", "480") : L("RulesManager", "485")
        RulesListView.Add(, activeText, displayName, rule.match, rule.matchType, maxText, rule.x, rule.y, rule.w, rule.h)
    }
    
    UpdateRuleButtons(false)
}

; ============================================================
UpdateRuleButtons(hasSelection) {
    global BtnEdit, BtnToggle, BtnDelete
    
    if (!IsObject(BtnEdit))
        return
    
    BtnEdit.Enabled := hasSelection
    BtnToggle.Enabled := hasSelection
    BtnDelete.Enabled := hasSelection
}

; ============================================================
OnRuleSelect(LV, Item, Selected) {
    ; Prüfen ob irgendein Eintrag ausgewählt ist
    hasSelection := (LV.GetNext(0) > 0)
    UpdateRuleButtons(hasSelection)
}

; ============================================================
NewRuleFromManager(*) {
    global RulesManagerGui
    RulesManagerGui.Destroy()
    RulesManagerGui := ""
    ShowWindowPicker()
}

; ============================================================
ToggleGlobalFromManager() {
    global RulesManagerGui
    
    ToggleGlobalPause()
    RulesManagerGui.Destroy()
    RulesManagerGui := ""
    ShowRulesManager()
}

; ============================================================
CloseRulesManager() {
    global RulesManagerGui
    RulesManagerGui.Destroy()
    RulesManagerGui := ""
    SetTimer(CheckWindows, 500)
}

; ============================================================
ToggleRuleFromList(ctrl, *) {
    global WindowRules, ProcessedWindows, RulesListView, AppName
    
    row := RulesListView.GetNext(0, "Focused")
    if (row = 0 || row > WindowRules.Length)
        return
    
    rule := WindowRules[row]
    
    rule.enabled := !rule.enabled
    WindowRules[row] := rule
    
    SaveRules()
    
    activeText := rule.enabled ? "✓" : "✗"
    RulesListView.Modify(row, , activeText)
    
    if (!rule.enabled)
        ResetProcessedForMatch(rule.match, rule.matchType)
    
    msgKey := rule.enabled ? "935" : "940"
    displayName := GetRuleDisplayName(rule)
    TrayTip(AppName, L("Messages", msgKey) " " displayName, 1)
}

; ============================================================
EditRuleFromList(ctrl, *) {
    global WindowRules, EditingRuleIndex, RulesManagerGui, RulesListView
    
    row := RulesListView.GetNext(0, "Focused")
    if (row = 0 || row > WindowRules.Length)
        return
    
    EditingRuleIndex := row
    rule := WindowRules[row]
    
    RulesManagerGui.Destroy()
    RulesManagerGui := ""
    EditRule(rule)
}

; ============================================================
DeleteRuleFromList(ctrl, *) {
    global WindowRules, ProcessedWindows, RulesListView, AppName
    
    row := RulesListView.GetNext(0, "Focused")
    if (row = 0 || row > WindowRules.Length)
        return
    
    rule := WindowRules[row]
    displayName := GetRuleDisplayName(rule)
    
    result := MsgBox(L("Messages", "970") "`n'" displayName "'", L("Messages", "975"), "YesNo Icon? 4096")
    if (result != "Yes")
        return
    
    WindowRules.RemoveAt(row)
    SaveRules()
    ResetProcessedForMatch(rule.match, rule.matchType)
    RulesListView.Delete(row)
    
    UpdateRuleButtons(false)
    
    TrayTip(AppName, L("Messages", "930") " " displayName, 1)
}

; ============================================================
EditRule(rule) {
    global MyGui, MyEdX, MyEdY, MyEdW, MyEdH, MyMatchDDL, MyMaximizeChk, MyRuleName, MyEnabledChk
    global CaptureClass, CaptureTitle, CaptureHwnd, AppName
    
    if (IsGuiVisible(MyGui)) {
        WinActivate("ahk_id " MyGui.Hwnd)
        return
    }
    
    CaptureClass := (rule.matchType = "class") ? rule.match : ""
    CaptureTitle := (rule.matchType = "title") ? rule.match : ""
    CaptureHwnd := 0
    
    FindMatchingWindow(rule)
    
    MyGui := Gui("+AlwaysOnTop", AppName " - " L("EditRule", "600"))
    MyGui.SetFont("s10")
    
    MyGui.Add("GroupBox", "w400 h140", L("EditRule", "605"))
    MyGui.Add("Text", "xp+10 yp+25", L("EditRule", "610"))
    MyRuleName := MyGui.Add("Edit", "x100 yp-3 w295", rule.name)
    MyGui.Add("Text", "x15 yp+35", L("EditRule", "615"))
    MyGui.Add("Edit", "x100 yp-3 w295 ReadOnly", rule.match)
    MyGui.Add("Text", "x15 yp+35", L("EditRule", "620"))
    typeText := rule.matchType = "class" ? L("CaptureWindow", "550") : L("CaptureWindow", "555")
    MyGui.Add("Edit", "x100 yp-3 w295 ReadOnly", typeText)
    
    MyEnabledChk := MyGui.Add("Checkbox", "x15 yp+35", L("EditRule", "625"))
    MyEnabledChk.Value := rule.enabled
    
    MyGui.Add("GroupBox", "x10 yp+35 w400 h130", L("EditRule", "630"))
    
    MyMaximizeChk := MyGui.Add("Checkbox", "xp+10 yp+25", L("EditRule", "635"))
    MyMaximizeChk.Value := rule.maximize
    MyMaximizeChk.OnEvent("Click", OnMaximizeToggle)
    
    MyGui.Add("Text", "x20 yp+35", "X:")
    MyEdX := MyGui.Add("Edit", "x40 yp-3 w70 Number", rule.x)
    MyGui.Add("Text", "x120 yp+3", "Y:")
    MyEdY := MyGui.Add("Edit", "x145 yp-3 w70 Number", rule.y)
    MyGui.Add("Text", "x225 yp+3", "W:")
    MyEdW := MyGui.Add("Edit", "x255 yp-3 w70 Number", rule.w)
    MyGui.Add("Text", "x335 yp+3", "H:")
    MyEdH := MyGui.Add("Edit", "x360 yp-3 w45 Number", rule.h)
    
    MyGui.Add("Text", "x20 yp+40", L("EditRule", "640"))
    chooseIndex := (rule.matchType = "class") ? 1 : 2
    MyMatchDDL := MyGui.Add("DropDownList", "x120 yp-3 w150 Disabled Choose" chooseIndex, [L("CaptureWindow", "550"), L("CaptureWindow", "555")])
    
    if (rule.maximize) {
        MyEdX.Enabled := false
        MyEdY.Enabled := false
        MyEdW.Enabled := false
        MyEdH.Enabled := false
    }
    
    ; Buttons mit gleichem Abstand: x10, x150, x290 (Abstand jeweils 20px)
    MyGui.Add("Button", "x10 yp+50 w120", L("EditRule", "645")).OnEvent("Click", DoSaveEditedRule)
    MyGui.Add("Button", "x150 yp w120", L("EditRule", "650")).OnEvent("Click", DoTestEditedRule)
    MyGui.Add("Button", "x290 yp w120", L("EditRule", "655")).OnEvent("Click", DoCancelToManager)
    MyGui.OnEvent("Close", DoCancelToManager)
    
    MyGui.Show()
}

; ============================================================
FindMatchingWindow(rule) {
    global CaptureHwnd
    
    CaptureHwnd := 0
    
    for hwnd in WinGetList() {
        try {
            if (rule.matchType = "class") {
                wclass := WinGetClass(hwnd)
                if (wclass = rule.match) {
                    CaptureHwnd := hwnd
                    return
                }
            } else if (rule.matchType = "title") {
                title := WinGetTitle(hwnd)
                if (title && InStr(title, rule.match)) {
                    CaptureHwnd := hwnd
                    return
                }
            }
        }
    }
}

; ============================================================
DoTestEditedRule(*) {
    global CaptureHwnd, MyEdX, MyEdY, MyEdW, MyEdH, MyMaximizeChk
    global EditingRuleIndex, WindowRules
    
    if (!CaptureHwnd || !WinExist("ahk_id " CaptureHwnd)) {
        if (EditingRuleIndex > 0 && EditingRuleIndex <= WindowRules.Length) {
            FindMatchingWindow(WindowRules[EditingRuleIndex])
        }
    }
    
    if (!CaptureHwnd || !WinExist("ahk_id " CaptureHwnd)) {
        MsgBox(L("Messages", "950"), L("Messages", "995"), "Icon! 4096")
        return
    }
    
    try {
        if (MyMaximizeChk.Value) {
            WinMaximize("ahk_id " CaptureHwnd)
        } else {
            WinMove(Integer(MyEdX.Value), Integer(MyEdY.Value),
                    Integer(MyEdW.Value), Integer(MyEdH.Value), "ahk_id " CaptureHwnd)
        }
    }
}

; ============================================================
DoSaveEditedRule(*) {
    global WindowRules, ProcessedWindows, EditingRuleIndex, AppName
    global MyGui, MyEdX, MyEdY, MyEdW, MyEdH, MyMaximizeChk, MyRuleName, MyEnabledChk
    
    if (EditingRuleIndex = 0 || EditingRuleIndex > WindowRules.Length) {
        MsgBox(L("Messages", "995"), L("Messages", "995"), "Icon! 4096")
        MyGui.Destroy()
        MyGui := ""
        ShowRulesManager()
        return
    }
    
    rule := WindowRules[EditingRuleIndex]
    
    ruleName := MyRuleName.Value
    targetX := Integer(MyEdX.Value)
    targetY := Integer(MyEdY.Value)
    targetW := Integer(MyEdW.Value)
    targetH := Integer(MyEdH.Value)
    doMaximize := MyMaximizeChk.Value
    isEnabled := MyEnabledChk.Value
    
    WindowRules[EditingRuleIndex] := {
        name: ruleName,
        match: rule.match,
        matchType: rule.matchType,
        maximize: doMaximize,
        enabled: isEnabled,
        x: targetX,
        y: targetY,
        w: targetW,
        h: targetH
    }
    
    SaveRules()
    ResetProcessedForMatch(rule.match, rule.matchType)
    
    displayName := (ruleName != "") ? ruleName : rule.match
    
    EditingRuleIndex := 0
    MyGui.Destroy()
    MyGui := ""
    TrayTip(AppName, L("Messages", "925") " " displayName, 1)
    
    ShowRulesManager()
}

; ============================================================
DoCancelToManager(*) {
    global MyGui, EditingRuleIndex
    EditingRuleIndex := 0
    MyGui.Destroy()
    MyGui := ""
    ShowRulesManager()
}

; ============================================================
ShowWindowPicker(*) {
    global EditingRuleIndex, WindowPickerGui, MyGui, AppName
    
    if (IsGuiVisible(WindowPickerGui)) {
        WinActivate("ahk_id " WindowPickerGui.Hwnd)
        return
    }
    
    if (IsGuiVisible(MyGui)) {
        MyGui.Destroy()
        MyGui := ""
    }
    
    EditingRuleIndex := 0
    
    SetTimer(CheckWindows, 0)
    
    windowList := []
    for hwnd in WinGetList() {
        try {
            title := WinGetTitle(hwnd)
            wclass := WinGetClass(hwnd)
            if (title && title != "Program Manager" && wclass != "AutoHotkeyGUI") {
                windowList.Push({hwnd: hwnd, title: title, class: wclass})
            }
        }
    }
    
    if (windowList.Length = 0) {
        MsgBox(L("Messages", "960"), L("Messages", "995"), "Icon! 4096")
        SetTimer(CheckWindows, 500)
        return
    }
    
    WindowPickerGui := Gui("+AlwaysOnTop", AppName " - " L("WindowPicker", "700"))
    WindowPickerGui.SetFont("s10")
    
    WindowPickerGui.Add("Text", , L("WindowPicker", "705"))
    
    LV := WindowPickerGui.Add("ListView", "w500 h300 vWindowLV", [L("WindowPicker", "710"), L("WindowPicker", "715")])
    LV.OnEvent("DoubleClick", SelectFromList)
    
    for win in windowList
        LV.Add(, win.title, win.class)
    
    LV.ModifyCol(1, 300)
    LV.ModifyCol(2, 180)
    
    ; Buttons mit gleichem Abstand
    WindowPickerGui.Add("Button", "x10 w100", L("WindowPicker", "720")).OnEvent("Click", SelectFromList)
    WindowPickerGui.Add("Button", "x120 yp w100", L("WindowPicker", "725")).OnEvent("Click", (*) => ClosePickerGui())
    WindowPickerGui.OnEvent("Close", (*) => ClosePickerGui())
    
    WindowPickerGui.windowList := windowList
    WindowPickerGui.Show()
}

; ============================================================
ClosePickerGui() {
    global WindowPickerGui
    WindowPickerGui.Destroy()
    WindowPickerGui := ""
    ShowRulesManager()
}

; ============================================================
SelectFromList(ctrl, *) {
    global WindowPickerGui
    
    LV := WindowPickerGui["WindowLV"]
    
    row := LV.GetNext(0, "Focused")
    if (row = 0) {
        MsgBox(L("Messages", "965"), L("Messages", "995"), "Icon! 4096")
        return
    }
    
    selectedWin := WindowPickerGui.windowList[row]
    WindowPickerGui.Destroy()
    WindowPickerGui := ""
    CaptureSpecificWindow(selectedWin.hwnd)
}

; ============================================================
CaptureWindow(*) {
    global LastActiveWindow, EditingRuleIndex, MyGui
    
    if (IsGuiVisible(MyGui)) {
        WinActivate("ahk_id " MyGui.Hwnd)
        return
    }
    
    EditingRuleIndex := 0
    
    SetTimer(CheckWindows, 0)
    
    hwnd := 0
    try {
        hwnd := WinGetID("A")
        wclass := WinGetClass(hwnd)
        if (wclass = "Shell_TrayWnd" || wclass = "AutoHotkeyGUI")
            hwnd := LastActiveWindow
    } catch {
        hwnd := LastActiveWindow
    }
    
    if (!hwnd || !WinExist("ahk_id " hwnd)) {
        ShowWindowPicker()
        return
    }
    
    CaptureSpecificWindow(hwnd)
}

; ============================================================
CaptureSpecificWindow(hwnd) {
    global CaptureHwnd, CaptureClass, CaptureTitle, AppName
    global MyGui, MyEdX, MyEdY, MyEdW, MyEdH, MyMatchDDL, MyMaximizeChk, MyRuleName
    global ToolTipControls
    
    if (!WinExist("ahk_id " hwnd)) {
        MsgBox(L("Messages", "955"), L("Messages", "995"), "Icon! 4096")
        ShowRulesManager()
        return
    }
    
    title := WinGetTitle("ahk_id " hwnd)
    wclass := WinGetClass("ahk_id " hwnd)
    WinGetPos(&curX, &curY, &curW, &curH, "ahk_id " hwnd)
    pid := WinGetPID("ahk_id " hwnd)
    processName := ProcessGetName(pid)
    
    CaptureHwnd := hwnd
    CaptureClass := wclass
    CaptureTitle := title
    
    ; ToolTip-Map leeren für neuen Dialog
    ToolTipControls := Map()
    
    MyGui := Gui("+AlwaysOnTop", AppName " - " L("CaptureWindow", "500"))
    MyGui.SetFont("s10")
    
    MyGui.Add("GroupBox", "w400 h50", L("CaptureWindow", "505"))
    MyRuleName := MyGui.Add("Edit", "xp+10 yp+20 w380")
    
    MyGui.Add("GroupBox", "x10 yp+45 w400 h105", L("CaptureWindow", "510"))
    MyGui.Add("Text", "xp+10 yp+25", L("CaptureWindow", "515"))
    edTitle := MyGui.Add("Edit", "x100 yp-3 w295 h21 ReadOnly", title)
    ToolTipControls[edTitle.Hwnd] := title
    
    MyGui.Add("Text", "x15 yp+28", L("CaptureWindow", "520"))
    edClass := MyGui.Add("Edit", "x100 yp-3 w295 h21 ReadOnly", wclass)
    ToolTipControls[edClass.Hwnd] := wclass
    
    MyGui.Add("Text", "x15 yp+28", L("CaptureWindow", "525"))
    edProcess := MyGui.Add("Edit", "x100 yp-3 w295 h21 ReadOnly", processName)
    ToolTipControls[edProcess.Hwnd] := processName
    
    MyGui.Add("GroupBox", "x10 yp+35 w400 h55", L("CaptureWindow", "530"))
    MyGui.Add("Text", "xp+10 yp+25", "X: " curX "  Y: " curY "  W: " curW "  H: " curH)
    
    MyGui.Add("GroupBox", "x10 yp+45 w400 h130", L("CaptureWindow", "535"))
    
    MyMaximizeChk := MyGui.Add("Checkbox", "xp+10 yp+25", L("CaptureWindow", "540"))
    MyMaximizeChk.OnEvent("Click", OnMaximizeToggle)
    
    MyGui.Add("Text", "x20 yp+35", "X:")
    MyEdX := MyGui.Add("Edit", "x40 yp-3 w70 Number", curX)
    MyGui.Add("Text", "x120 yp+3", "Y:")
    MyEdY := MyGui.Add("Edit", "x145 yp-3 w70 Number", curY)
    MyGui.Add("Text", "x225 yp+3", "W:")
    MyEdW := MyGui.Add("Edit", "x255 yp-3 w70 Number", curW)
    MyGui.Add("Text", "x335 yp+3", "H:")
    MyEdH := MyGui.Add("Edit", "x360 yp-3 w45 Number", curH)
    
    MyGui.Add("Text", "x20 yp+40", L("CaptureWindow", "545"))
    MyMatchDDL := MyGui.Add("DropDownList", "x120 yp-3 w150 Choose1", [L("CaptureWindow", "550"), L("CaptureWindow", "555")])
    
    ; Buttons mit gleichem Abstand: x10, x150, x290 (Abstand jeweils 20px)
    MyGui.Add("Button", "x10 yp+50 w120", L("CaptureWindow", "560")).OnEvent("Click", DoAddRule)
    MyGui.Add("Button", "x150 yp w120", L("CaptureWindow", "565")).OnEvent("Click", DoTestRule)
    MyGui.Add("Button", "x290 yp w120", L("CaptureWindow", "570")).OnEvent("Click", DoCancelToManager)
    MyGui.OnEvent("Close", DoCancelToManager)
    
    MyGui.Show()
}

; ============================================================
OnMaximizeToggle(*) {
    global MyEdX, MyEdY, MyEdW, MyEdH, MyMaximizeChk
    
    isMaximize := MyMaximizeChk.Value
    
    MyEdX.Enabled := !isMaximize
    MyEdY.Enabled := !isMaximize
    MyEdW.Enabled := !isMaximize
    MyEdH.Enabled := !isMaximize
}

; ============================================================
DoAddRule(*) {
    global CaptureHwnd, CaptureClass, CaptureTitle, AppName
    global WindowRules, ProcessedWindows
    global MyGui, MyEdX, MyEdY, MyEdW, MyEdH, MyMatchDDL, MyMaximizeChk, MyRuleName
    
    ruleName := MyRuleName.Value
    targetX := Integer(MyEdX.Value)
    targetY := Integer(MyEdY.Value)
    targetW := Integer(MyEdW.Value)
    targetH := Integer(MyEdH.Value)
    matchChoice := MyMatchDDL.Text
    doMaximize := MyMaximizeChk.Value
    
    ; Vergleich mit lokalisiertem Text
    matchType := (matchChoice = L("CaptureWindow", "550")) ? "class" : "title"
    matchValue := (matchType = "class") ? CaptureClass : CaptureTitle
    
    existingIndex := 0
    for i, rule in WindowRules {
        if (rule.match = matchValue && rule.matchType = matchType) {
            existingIndex := i
            break
        }
    }
    
    newRule := {
        name: ruleName,
        match: matchValue,
        matchType: matchType,
        maximize: doMaximize,
        enabled: true,
        x: targetX,
        y: targetY,
        w: targetW,
        h: targetH
    }
    
    if (existingIndex > 0) {
        newRule.enabled := WindowRules[existingIndex].enabled
        WindowRules[existingIndex] := newRule
        msgKey := "925"
    } else {
        WindowRules.Push(newRule)
        msgKey := "920"
    }
    
    SaveRules()
    
    if (ProcessedWindows.Has(CaptureHwnd))
        ProcessedWindows.Delete(CaptureHwnd)
    
    ResetProcessedForMatch(matchValue, matchType)
    
    displayName := (ruleName != "") ? ruleName : matchValue
    
    MyGui.Destroy()
    MyGui := ""
    TrayTip(AppName, L("Messages", msgKey) " " displayName, 1)
    
    ShowRulesManager()
}

; ============================================================
ResetProcessedForMatch(matchValue, matchType) {
    global ProcessedWindows
    
    toRemove := []
    
    for hwnd, _ in ProcessedWindows {
        try {
            if (matchType = "class") {
                wclass := WinGetClass(hwnd)
                if (wclass = matchValue)
                    toRemove.Push(hwnd)
            } else if (matchType = "title") {
                title := WinGetTitle(hwnd)
                if (InStr(title, matchValue))
                    toRemove.Push(hwnd)
            }
        }
    }
    
    for hwnd in toRemove
        ProcessedWindows.Delete(hwnd)
}

; ============================================================
DoTestRule(*) {
    global CaptureHwnd, MyEdX, MyEdY, MyEdW, MyEdH, MyMaximizeChk
    
    try {
        if (MyMaximizeChk.Value) {
            WinMaximize("ahk_id " CaptureHwnd)
        } else {
            WinMove(Integer(MyEdX.Value), Integer(MyEdY.Value),
                    Integer(MyEdW.Value), Integer(MyEdH.Value), "ahk_id " CaptureHwnd)
        }
    }
}

; ============================================================
DoCancel(*) {
    global MyGui, EditingRuleIndex
    EditingRuleIndex := 0
    MyGui.Destroy()
    MyGui := ""
    SetTimer(CheckWindows, 500)
}

; ============================================================
CheckWindows() {
    global WindowRules, ProcessedWindows, GlobalPaused
    
    if (GlobalPaused)
        return
    
    for rule in WindowRules {
        if (!rule.enabled)
            continue
        
        try {
            for hwnd in WinGetList() {
                try {
                    if (rule.matchType = "title") {
                        title := WinGetTitle(hwnd)
                        if (title && InStr(title, rule.match))
                            ApplyRule(hwnd, rule)
                    } else if (rule.matchType = "class") {
                        wclass := WinGetClass(hwnd)
                        if (wclass = rule.match)
                            ApplyRule(hwnd, rule)
                    }
                }
            }
        }
    }
}

; ============================================================
ApplyRule(hwnd, rule) {
    global ProcessedWindows, AppName
    
    if (ProcessedWindows.Has(hwnd))
        return
    
    try {
        if (rule.maximize) {
            WinMaximize(hwnd)
        } else {
            WinMove(rule.x, rule.y, rule.w, rule.h, hwnd)
        }
        ProcessedWindows[hwnd] := true
        displayName := GetRuleDisplayName(rule)
        TrayTip(AppName, L("Messages", "945") " " displayName, 1)
    }
}

; ============================================================
ShowRules(*) {
    ShowRulesManager()
}
