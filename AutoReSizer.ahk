#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ============================================================
; AutoReSizer - Window Size/Position Manager
; Version: 1.5.6
; ============================================================

global AppName := "AutoReSizer"
global AppVersion := "1.5.6"
global AppAuthor := "HJS"
global AppGitHub := "https://github.com/HJS-cpu/AutoReSizer"
global AppEmail := "autoresizer@gmx.com"

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

; Tracking woher Dialog geöffnet wurde
global CameFromRulesManager := false

; Hotkey-Einstellungen
global HotkeyEnabled := false
global HotkeyKey := ""
global CurrentHotkey := ""

; Hotkey für sofortiges Anwenden der Regeln
global ApplyRulesHotkeyEnabled := false
global ApplyRulesHotkeyKey := ""
global CurrentApplyRulesHotkey := ""

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
        
        if (line = "" || SubStr(line, 1, 1) = ";")
            continue
        
        if (SubStr(line, 1, 1) = "[" && SubStr(line, -1) = "]") {
            currentSection := SubStr(line, 2, -1)
            continue
        }
        
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
        langName := SubStr(A_LoopFileName, 1, -4)
        
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
        MsgBox("No language files (.lng) found!", "Error", "Icon! 4096")
        ExitApp()
    }
    
    if (isFirstRun) {
        titleText := AppName
        promptText := ""
        okText := "OK"
        cancelText := ""
    } else {
        titleText := L("LanguageSelect", "800")
        promptText := L("LanguageSelect", "805")
        okText := L("LanguageSelect", "810")
        cancelText := L("LanguageSelect", "815")
    }
    LanguageGui := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox -SysMenu", titleText)
    LanguageGui.SetFont("s9")
    
    if (promptText != "")
        LanguageGui.Add("Text", "w200", promptText)
    
    langListBox := LanguageGui.Add("ListBox", "w200 h100 vLangSelect")
    
    selectedIndex := 1
    for i, lang in languages {
        langListBox.Add([lang.name])
        if (lang.file = CurrentLanguage)
            selectedIndex := i
    }
    langListBox.Choose(selectedIndex)
    
    if (!isFirstRun) {
        ; Buttons zentriert (2 Buttons à 70px mit 5px Abstand = 145px, Start bei x38)
        LanguageGui.Add("Button", "x38 w70", okText).OnEvent("Click", (*) => ApplyLanguageSelection(languages, isFirstRun))
        LanguageGui.Add("Button", "x113 yp w70", cancelText).OnEvent("Click", (*) => CloseLanguageSelect())
        LanguageGui.OnEvent("Close", (*) => CloseLanguageSelect())
    } else {
        ; Button zentriert (1 Button à 70px, Start bei x75)
        LanguageGui.Add("Button", "x75 w70", okText).OnEvent("Click", (*) => ApplyLanguageSelection(languages, isFirstRun))
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
    
    BuildTrayMenu()
    UpdateTrayIcon()
    
    if (!isFirstRun) {
        TrayTip(AppName, "Language changed", 1)
    }
}

; ============================================================
CloseLanguageSelect() {
    global LanguageGui
    LanguageGui.Destroy()
    LanguageGui := ""
}

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
ShowAbout(*) {
    global AboutGui, AppName, AppVersion, AppAuthor, AppGitHub, AppEmail
    
    if (IsGuiVisible(AboutGui)) {
        WinActivate("ahk_id " AboutGui.Hwnd)
        return
    }
    AboutGui := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox", L("About", "200"))
    
    AboutGui.SetFont("s11 bold")
    AboutGui.Add("Text", "x20 w280 Center", AppName " v" AppVersion)
    
    AboutGui.SetFont("s9 norm")
    AboutGui.Add("Text", "x20 w280 Center", L("About", "210") " " AppAuthor)
    
    AboutGui.SetFont("s8 norm cGray")
    AboutGui.Add("Text", "x20 w280 Center", L("About", "230"))
    
    AboutGui.SetFont("s8 norm cGray")
    AboutGui.Add("Text", "x20 w280 Center", L("About", "235"))
    
    AboutGui.Add("Text", "x10 h10", "")
    
    AboutGui.SetFont("s9 bold cBlack")
    AboutGui.Add("Text", "x20 w45", "WWW:")
    AboutGui.SetFont("s9 bold")
    AboutGui.Add("Link", "x70 yp -TabStop", '<a href="' AppGitHub '">' AppGitHub '</a>')
    
    AboutGui.SetFont("s9 bold cBlack")
    AboutGui.Add("Text", "x20 w45", "E-Mail:")
    AboutGui.SetFont("s9 bold")
    AboutGui.Add("Link", "x70 yp -TabStop", '<a href="mailto:' AppEmail '">' AppEmail '</a>')
    
    AboutGui.Add("Text", "x10 h15", "")
    
    AboutGui.SetFont("s9 norm")
    ; Button zentriert (1 Button à 70px bei Fensterbreite ~320px, Start bei x125)
    AboutGui.Add("Button", "x125 w70", L("About", "225")).OnEvent("Click", (*) => CloseAbout())
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
LoadSettings() {
    global IniFile, HotkeyEnabled, HotkeyKey, AutostartEnabled
    global ApplyRulesHotkeyEnabled, ApplyRulesHotkeyKey

    if (!FileExist(IniFile))
        return

    HotkeyEnabled := IniRead(IniFile, "Settings", "HotkeyEnabled", "0") = "1"
    HotkeyKey := IniRead(IniFile, "Settings", "HotkeyKey", "")

    ApplyRulesHotkeyEnabled := IniRead(IniFile, "Settings", "ApplyRulesHotkeyEnabled", "0") = "1"
    ApplyRulesHotkeyKey := IniRead(IniFile, "Settings", "ApplyRulesHotkeyKey", "")

    AutostartEnabled := CheckAutostart()
}

; ============================================================
SaveSettings() {
    global IniFile, HotkeyEnabled, HotkeyKey
    global ApplyRulesHotkeyEnabled, ApplyRulesHotkeyKey

    IniWrite(HotkeyEnabled ? "1" : "0", IniFile, "Settings", "HotkeyEnabled")
    IniWrite(HotkeyKey, IniFile, "Settings", "HotkeyKey")
    IniWrite(ApplyRulesHotkeyEnabled ? "1" : "0", IniFile, "Settings", "ApplyRulesHotkeyEnabled")
    IniWrite(ApplyRulesHotkeyKey, IniFile, "Settings", "ApplyRulesHotkeyKey")
}

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
RegisterHotkey() {
    global HotkeyEnabled, HotkeyKey, CurrentHotkey
    global ApplyRulesHotkeyEnabled, ApplyRulesHotkeyKey, CurrentApplyRulesHotkey

    ; Alten Capture-Hotkey deaktivieren falls vorhanden
    if (CurrentHotkey != "") {
        try {
            Hotkey(CurrentHotkey, "Off")
        }
        CurrentHotkey := ""
    }

    ; Alten Apply-Rules-Hotkey deaktivieren falls vorhanden
    if (CurrentApplyRulesHotkey != "") {
        try {
            Hotkey(CurrentApplyRulesHotkey, "Off")
        }
        CurrentApplyRulesHotkey := ""
    }

    ; Capture-Hotkey registrieren
    if (HotkeyEnabled && HotkeyKey != "") {
        try {
            newHotkey := "^#" HotkeyKey
            Hotkey(newHotkey, HotkeyCallback, "On")
            CurrentHotkey := newHotkey
        } catch as err {
            MsgBox("Hotkey error: " err.Message, L("Messages", "995"), "Icon! 4096")
        }
    }

    ; Apply-Rules-Hotkey registrieren
    if (ApplyRulesHotkeyEnabled && ApplyRulesHotkeyKey != "") {
        try {
            newApplyHotkey := "^#" ApplyRulesHotkeyKey
            Hotkey(newApplyHotkey, ApplyRulesHotkeyCallback, "On")
            CurrentApplyRulesHotkey := newApplyHotkey
        } catch as err {
            MsgBox("Hotkey error: " err.Message, L("Messages", "995"), "Icon! 4096")
        }
    }

    UpdateTrayIcon()
}

; ============================================================
HotkeyCallback(*) {
    CaptureWindow()
}

; ============================================================
ApplyRulesHotkeyCallback(*) {
    ApplyAllRulesNow()
}

; ============================================================
ApplyAllRulesNow() {
    global WindowRules, ProcessedWindows, GlobalPaused, AppName

    if (GlobalPaused)
        return

    appliedCount := 0

    for rule in WindowRules {
        if (!rule.enabled)
            continue

        try {
            for hwnd in WinGetList() {
                try {
                    matched := false

                    if (rule.matchType = "title") {
                        title := WinGetTitle(hwnd)
                        if (title && InStr(title, rule.match))
                            matched := true
                    } else if (rule.matchType = "class") {
                        wclass := WinGetClass(hwnd)
                        if (wclass = rule.match)
                            matched := true
                    }

                    if (matched) {
                        ; Anwenden auch wenn bereits verarbeitet
                        if (rule.maximize) {
                            WinMaximize(hwnd)
                        } else {
                            WinMove(rule.x, rule.y, rule.w, rule.h, hwnd)
                        }
                        ProcessedWindows[hwnd] := true
                        appliedCount++
                    }
                }
            }
        }
    }

    if (appliedCount > 0)
        TrayTip(AppName, L("Messages", "946") " " appliedCount, 1)
    else
        TrayTip(AppName, L("Messages", "947"), 1)
}

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
ShowSettings(*) {
    global SettingsGui, HotkeyEnabled, HotkeyKey, AutostartEnabled, AppName
    global ApplyRulesHotkeyEnabled, ApplyRulesHotkeyKey
    global SettingsHotkeyEdit, SettingsHotkeyChk, SettingsAutostartChk
    global SettingsApplyRulesHotkeyEdit, SettingsApplyRulesHotkeyChk

    if (IsGuiVisible(SettingsGui)) {
        WinActivate("ahk_id " SettingsGui.Hwnd)
        return
    }

    AutostartEnabled := CheckAutostart()

    SettingsGui := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox -Resize", L("Settings", "300"))
    SettingsGui.SetFont("s9")

    yPos := 10
    frameHeight := 70
    frameSpacing := 8

    ; Frame 1: Hotkey für Fenster erfassen
    SettingsGui.Add("GroupBox", "x10 y" yPos " w280 h" frameHeight, L("Settings", "305"))
    SettingsHotkeyChk := SettingsGui.Add("Checkbox", "x20 y" (yPos + 20), L("Settings", "310"))
    SettingsHotkeyChk.Value := HotkeyEnabled
    SettingsHotkeyChk.OnEvent("Click", OnHotkeyToggle)
    SettingsGui.Add("Text", "x20 y" (yPos + 45), L("Settings", "315"))
    SettingsHotkeyEdit := SettingsGui.Add("Edit", "x90 y" (yPos + 42) " w30 Uppercase Limit1 Center", HotkeyKey)
    SettingsHotkeyEdit.Enabled := HotkeyEnabled
    SettingsGui.Add("Text", "x130 y" (yPos + 45) " cGray", L("Settings", "320"))

    yPos += frameHeight + frameSpacing

    ; Frame 2: Hotkey für Regeln anwenden
    SettingsGui.Add("GroupBox", "x10 y" yPos " w280 h" frameHeight, L("Settings", "360"))
    SettingsApplyRulesHotkeyChk := SettingsGui.Add("Checkbox", "x20 y" (yPos + 20), L("Settings", "365"))
    SettingsApplyRulesHotkeyChk.Value := ApplyRulesHotkeyEnabled
    SettingsApplyRulesHotkeyChk.OnEvent("Click", OnApplyRulesHotkeyToggle)
    SettingsGui.Add("Text", "x20 y" (yPos + 45), L("Settings", "315"))
    SettingsApplyRulesHotkeyEdit := SettingsGui.Add("Edit", "x90 y" (yPos + 42) " w30 Uppercase Limit1 Center", ApplyRulesHotkeyKey)
    SettingsApplyRulesHotkeyEdit.Enabled := ApplyRulesHotkeyEnabled
    SettingsGui.Add("Text", "x130 y" (yPos + 45) " cGray", L("Settings", "320"))

    yPos += frameHeight + frameSpacing

    ; Frame 3: Windows-Start
    smallFrameHeight := 45
    SettingsGui.Add("GroupBox", "x10 y" yPos " w280 h" smallFrameHeight, L("Settings", "330"))
    SettingsAutostartChk := SettingsGui.Add("Checkbox", "x20 y" (yPos + 18), L("Settings", "335"))
    SettingsAutostartChk.Value := AutostartEnabled

    yPos += smallFrameHeight + frameSpacing

    ; Frame 4: Sprache
    SettingsGui.Add("GroupBox", "x10 y" yPos " w280 h" smallFrameHeight, L("Settings", "350"))
    SettingsGui.Add("Button", "x20 y" (yPos + 15) " w120", L("Settings", "355")).OnEvent("Click", (*) => OpenLanguageFromSettings())

    yPos += smallFrameHeight + frameSpacing + 5

    ; Buttons zentriert (2 Buttons à 80px mit 5px Abstand = 165px, Start bei x68)
    SettingsGui.Add("Button", "x68 y" yPos " w80", L("Settings", "340")).OnEvent("Click", SaveSettingsAndClose)
    SettingsGui.Add("Button", "x153 y" yPos " w80", L("Settings", "345")).OnEvent("Click", (*) => CloseSettings())
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
OnApplyRulesHotkeyToggle(*) {
    global SettingsApplyRulesHotkeyEdit, SettingsApplyRulesHotkeyChk

    SettingsApplyRulesHotkeyEdit.Enabled := SettingsApplyRulesHotkeyChk.Value
}

; ============================================================
SaveSettingsAndClose(*) {
    global SettingsGui, SettingsHotkeyEdit, SettingsHotkeyChk, SettingsAutostartChk
    global SettingsApplyRulesHotkeyEdit, SettingsApplyRulesHotkeyChk
    global HotkeyEnabled, HotkeyKey, AppName
    global ApplyRulesHotkeyEnabled, ApplyRulesHotkeyKey

    newKey := SettingsHotkeyEdit.Value
    newEnabled := SettingsHotkeyChk.Value
    newApplyRulesKey := SettingsApplyRulesHotkeyEdit.Value
    newApplyRulesEnabled := SettingsApplyRulesHotkeyChk.Value
    newAutostart := SettingsAutostartChk.Value

    ; Capture-Hotkey validieren
    if (newEnabled && newKey != "") {
        if (!RegExMatch(newKey, "^[A-Z0-9]$")) {
            MsgBox(L("Messages", "985"), L("Messages", "980"), "Icon! 4096")
            return
        }
    }

    ; Apply-Rules-Hotkey validieren
    if (newApplyRulesEnabled && newApplyRulesKey != "") {
        if (!RegExMatch(newApplyRulesKey, "^[A-Z0-9]$")) {
            MsgBox(L("Messages", "985"), L("Messages", "980"), "Icon! 4096")
            return
        }
    }

    ; Prüfen ob beide Hotkeys gleich sind
    if (newEnabled && newApplyRulesEnabled && newKey != "" && newApplyRulesKey != "" && newKey = newApplyRulesKey) {
        MsgBox(L("Messages", "986"), L("Messages", "980"), "Icon! 4096")
        return
    }

    HotkeyEnabled := newEnabled
    HotkeyKey := newKey
    ApplyRulesHotkeyEnabled := newApplyRulesEnabled
    ApplyRulesHotkeyKey := newApplyRulesKey

    SaveSettings()
    RegisterHotkey()
    SetAutostart(newAutostart)

    SettingsGui.Destroy()
    SettingsGui := ""

    ; Tray-Tip für aktivierte Hotkeys
    tipMessages := []
    if (HotkeyEnabled && HotkeyKey != "")
        tipMessages.Push(L("Messages", "910") " Ctrl+Win+" HotkeyKey)
    if (ApplyRulesHotkeyEnabled && ApplyRulesHotkeyKey != "")
        tipMessages.Push(L("Messages", "911") " Ctrl+Win+" ApplyRulesHotkeyKey)

    if (tipMessages.Length > 0) {
        tipText := ""
        for msg in tipMessages {
            if (tipText != "")
                tipText .= "`n"
            tipText .= msg
        }
        TrayTip(AppName, tipText, 1)
    }
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
ShowRulesManager(*) {
    global WindowRules, GlobalPaused, AppName
    global RulesManagerGui, RulesListView, BtnEdit, BtnToggle, BtnDelete
    
    if (IsGuiVisible(RulesManagerGui)) {
        RefreshRulesList()
        WinActivate("ahk_id " RulesManagerGui.Hwnd)
        return
    }
    
    CloseAllDialogs()
    
    BtnEdit := ""
    BtnToggle := ""
    BtnDelete := ""
    
    SetTimer(CheckWindows, 0)
    
    RulesManagerGui := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox -Resize", L("RulesManager", "400"))
    RulesManagerGui.SetFont("s9")
    
    statusText := GlobalPaused ? "⚠️ " L("General", "130") : "✓ " L("General", "125")
    RulesManagerGui.Add("Text", "w500", L("RulesManager", "405") " " statusText)
    
    RulesListView := RulesManagerGui.Add("ListView", "w500 h200 vRulesLV", [
        L("RulesManager", "415"),
        L("RulesManager", "420"),
        L("RulesManager", "425"),
        L("RulesManager", "430"),
        L("RulesManager", "435"),
        "X", "Y", "W", "H"
    ])
    RulesListView.OnEvent("DoubleClick", EditRuleFromList)
    RulesListView.OnEvent("ItemSelect", OnRuleSelect)
    
    RulesListView.ModifyCol(1, "40 Center")
    RulesListView.ModifyCol(2, 90)
    RulesListView.ModifyCol(3, 100)
    RulesListView.ModifyCol(4, 45)
    RulesListView.ModifyCol(5, 35)
    RulesListView.ModifyCol(6, 40)
    RulesListView.ModifyCol(7, 40)
    RulesListView.ModifyCol(8, 40)
    RulesListView.ModifyCol(9, 40)
    
    ; Buttons zentriert (6 Buttons à 70px mit 5px Abstand = 445px, Start bei x38)
    RulesManagerGui.Add("Button", "x38 w70", L("RulesManager", "440")).OnEvent("Click", NewRuleFromManager)
    BtnEdit := RulesManagerGui.Add("Button", "x113 yp w70 Disabled", L("RulesManager", "445"))
    BtnEdit.OnEvent("Click", EditRuleFromList)
    BtnToggle := RulesManagerGui.Add("Button", "x188 yp w70 Disabled", L("RulesManager", "450"))
    BtnToggle.OnEvent("Click", ToggleRuleFromList)
    BtnDelete := RulesManagerGui.Add("Button", "x263 yp w70 Disabled", L("RulesManager", "455"))
    BtnDelete.OnEvent("Click", DeleteRuleFromList)
    pauseBtnText := GlobalPaused ? L("RulesManager", "460") : L("RulesManager", "465")
    RulesManagerGui.Add("Button", "x338 yp w70", pauseBtnText).OnEvent("Click", (*) => ToggleGlobalFromManager())
    RulesManagerGui.Add("Button", "x413 yp w70", L("RulesManager", "470")).OnEvent("Click", (*) => CloseRulesManager())
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
    hasSelection := (LV.GetNext(0) > 0)
    UpdateRuleButtons(hasSelection)
}

; ============================================================
NewRuleFromManager(*) {
    global RulesManagerGui, CameFromRulesManager
    CameFromRulesManager := true
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
    global WindowRules, EditingRuleIndex, RulesManagerGui, RulesListView, CameFromRulesManager
    
    row := RulesListView.GetNext(0, "Focused")
    if (row = 0 || row > WindowRules.Length)
        return
    
    EditingRuleIndex := row
    rule := WindowRules[row]
    
    CameFromRulesManager := true
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
    global CaptureClass, CaptureTitle, CaptureHwnd, AppName, ToolTipControls
    
    if (IsGuiVisible(MyGui)) {
        WinActivate("ahk_id " MyGui.Hwnd)
        return
    }
    
    CaptureClass := (rule.matchType = "class") ? rule.match : ""
    CaptureTitle := (rule.matchType = "title") ? rule.match : ""
    CaptureHwnd := 0
    
    FindMatchingWindow(rule)
    
    MyGui := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox -Resize", L("EditRule", "600"))
    MyGui.SetFont("s9")
    ToolTipControls := Map()
    
    MyGui.Add("GroupBox", "w320 h105", L("EditRule", "605"))
    MyGui.Add("Text", "xp+10 yp+18", L("EditRule", "610"))
    MyRuleName := MyGui.Add("Edit", "x80 yp-3 w240", rule.name)
    MyGui.Add("Text", "x15 yp+25", L("EditRule", "615"))
    MyGui.Add("Edit", "x80 yp-3 w240 ReadOnly", rule.match)
    MyGui.Add("Text", "x15 yp+25", L("EditRule", "620"))
    typeText := rule.matchType = "class" ? L("CaptureWindow", "550") : L("CaptureWindow", "555")
    MyGui.Add("Edit", "x80 yp-3 w240 ReadOnly", typeText)
    
    MyEnabledChk := MyGui.Add("Checkbox", "x15 yp+25", L("EditRule", "625"))
    MyEnabledChk.Value := rule.enabled
    
    MyGui.Add("GroupBox", "x10 yp+25 w320 h95", L("EditRule", "630"))
    
    MyMaximizeChk := MyGui.Add("Checkbox", "xp+10 yp+18", L("EditRule", "635"))
    MyMaximizeChk.Value := rule.maximize
    MyMaximizeChk.OnEvent("Click", OnMaximizeToggle)
    
    lblX := MyGui.Add("Text", "x20 yp+25 +0x100", "X:")
    MyEdX := MyGui.Add("Edit", "x38 yp-3 w50 Number", rule.x)
    lblY := MyGui.Add("Text", "x95 yp+3 +0x100", "Y:")
    MyEdY := MyGui.Add("Edit", "x113 yp-3 w50 Number", rule.y)
    lblW := MyGui.Add("Text", "x175 yp+3 +0x100", "W:")
    MyEdW := MyGui.Add("Edit", "x193 yp-3 w50 Number", rule.w)
    lblH := MyGui.Add("Text", "x255 yp+3 +0x100", "H:")
    MyEdH := MyGui.Add("Edit", "x273 yp-3 w50 Number", rule.h)

    ToolTipControls[lblX.Hwnd] := L("CaptureWindow", "575")
    ToolTipControls[lblY.Hwnd] := L("CaptureWindow", "576")
    ToolTipControls[lblW.Hwnd] := L("CaptureWindow", "577")
    ToolTipControls[lblH.Hwnd] := L("CaptureWindow", "578")
    
    MyGui.Add("Text", "x20 yp+28", L("EditRule", "640"))
    chooseIndex := (rule.matchType = "class") ? 1 : 2
    MyMatchDDL := MyGui.Add("DropDownList", "x100 yp-3 w120 Disabled Choose" chooseIndex, [L("CaptureWindow", "550"), L("CaptureWindow", "555")])
    
    if (rule.maximize) {
        MyEdX.Enabled := false
        MyEdY.Enabled := false
        MyEdW.Enabled := false
        MyEdH.Enabled := false
    }
    
    ; Buttons zentriert (3 Buttons à 100px mit 5px Abstand = 310px, Start bei x15)
    MyGui.Add("Button", "x15 yp+35 w100", L("EditRule", "645")).OnEvent("Click", DoSaveEditedRule)
    MyGui.Add("Button", "x120 yp w100", L("EditRule", "650")).OnEvent("Click", DoTestEditedRule)
    MyGui.Add("Button", "x225 yp w100", L("EditRule", "655")).OnEvent("Click", DoCancelToManager)
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
    global CameFromRulesManager
    
    if (EditingRuleIndex = 0 || EditingRuleIndex > WindowRules.Length) {
        MsgBox(L("Messages", "995"), L("Messages", "995"), "Icon! 4096")
        MyGui.Destroy()
        MyGui := ""
        if (CameFromRulesManager) {
            CameFromRulesManager := false
            ShowRulesManager()
        }
        SetTimer(CheckWindows, 500)
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
    
    if (CameFromRulesManager) {
        CameFromRulesManager := false
        ShowRulesManager()
    }
    SetTimer(CheckWindows, 500)
}

; ============================================================
DoCancelToManager(*) {
    global MyGui, EditingRuleIndex, CameFromRulesManager
    EditingRuleIndex := 0
    MyGui.Destroy()
    MyGui := ""
    if (CameFromRulesManager) {
        CameFromRulesManager := false
        ShowRulesManager()
    }
    SetTimer(CheckWindows, 500)
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
    
    WindowPickerGui := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox -Resize", L("WindowPicker", "700"))
    WindowPickerGui.SetFont("s9")
    
    WindowPickerGui.Add("Text", , L("WindowPicker", "705"))
    
    LV := WindowPickerGui.Add("ListView", "w400 h200 vWindowLV", [L("WindowPicker", "710"), L("WindowPicker", "715")])
    LV.OnEvent("DoubleClick", SelectFromList)
    
    for win in windowList
        LV.Add(, win.title, win.class)
    
    LV.ModifyCol(1, 230)
    LV.ModifyCol(2, 150)
    
    ; Buttons zentriert (2 Buttons à 80px mit 10px Abstand = 170px, Start bei x125)
    WindowPickerGui.Add("Button", "x125 w80", L("WindowPicker", "720")).OnEvent("Click", SelectFromList)
    WindowPickerGui.Add("Button", "x215 yp w80", L("WindowPicker", "725")).OnEvent("Click", (*) => ClosePickerGui())
    WindowPickerGui.OnEvent("Close", (*) => ClosePickerGui())
    
    WindowPickerGui.windowList := windowList
    WindowPickerGui.Show()
}

; ============================================================
ClosePickerGui() {
    global WindowPickerGui, CameFromRulesManager
    WindowPickerGui.Destroy()
    WindowPickerGui := ""
    if (CameFromRulesManager) {
        CameFromRulesManager := false
        ShowRulesManager()
    }
    SetTimer(CheckWindows, 500)
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
    global ToolTipControls, CameFromRulesManager
    
    if (!WinExist("ahk_id " hwnd)) {
        MsgBox(L("Messages", "955"), L("Messages", "995"), "Icon! 4096")
        if (CameFromRulesManager) {
            CameFromRulesManager := false
            ShowRulesManager()
        }
        SetTimer(CheckWindows, 500)
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
    
    ToolTipControls := Map()

    MyGui := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox -Resize", L("CaptureWindow", "500"))
    MyGui.SetFont("s9")
    
    MyGui.Add("GroupBox", "w320 h40", L("CaptureWindow", "505"))
    MyRuleName := MyGui.Add("Edit", "xp+10 yp+15 w300")
    
    MyGui.Add("GroupBox", "x10 yp+35 w320 h75", L("CaptureWindow", "510"))
    MyGui.Add("Text", "xp+10 yp+18", L("CaptureWindow", "515"))
    edTitle := MyGui.Add("Edit", "x80 yp-3 w240 h20 ReadOnly", title)
    ToolTipControls[edTitle.Hwnd] := title
    
    MyGui.Add("Text", "x15 yp+23", L("CaptureWindow", "520"))
    edClass := MyGui.Add("Edit", "x80 yp-3 w240 h20 ReadOnly", wclass)
    ToolTipControls[edClass.Hwnd] := wclass
    
    MyGui.Add("Text", "x15 yp+23", L("CaptureWindow", "525"))
    edProcess := MyGui.Add("Edit", "x80 yp-3 w240 h20 ReadOnly", processName)
    ToolTipControls[edProcess.Hwnd] := processName
    
    MyGui.Add("GroupBox", "x10 yp+30 w320 h35", L("CaptureWindow", "530"))
    MyGui.Add("Text", "xp+10 yp+15", "X: " curX "  Y: " curY "  W: " curW "  H: " curH)
    
    MyGui.Add("GroupBox", "x10 yp+30 w320 h95", L("CaptureWindow", "535"))
    
    MyMaximizeChk := MyGui.Add("Checkbox", "xp+10 yp+18", L("CaptureWindow", "540"))
    MyMaximizeChk.OnEvent("Click", OnMaximizeToggle)
    
    lblX := MyGui.Add("Text", "x20 yp+25 +0x100", "X:")
    MyEdX := MyGui.Add("Edit", "x38 yp-3 w50 Number", curX)
    lblY := MyGui.Add("Text", "x95 yp+3 +0x100", "Y:")
    MyEdY := MyGui.Add("Edit", "x113 yp-3 w50 Number", curY)
    lblW := MyGui.Add("Text", "x175 yp+3 +0x100", "W:")
    MyEdW := MyGui.Add("Edit", "x193 yp-3 w50 Number", curW)
    lblH := MyGui.Add("Text", "x255 yp+3 +0x100", "H:")
    MyEdH := MyGui.Add("Edit", "x273 yp-3 w50 Number", curH)

    ToolTipControls[lblX.Hwnd] := L("CaptureWindow", "575")
    ToolTipControls[lblY.Hwnd] := L("CaptureWindow", "576")
    ToolTipControls[lblW.Hwnd] := L("CaptureWindow", "577")
    ToolTipControls[lblH.Hwnd] := L("CaptureWindow", "578")
    
    MyGui.Add("Text", "x20 yp+28", L("CaptureWindow", "545"))
    MyMatchDDL := MyGui.Add("DropDownList", "x100 yp-3 w120 Choose1", [L("CaptureWindow", "550"), L("CaptureWindow", "555")])
    
    ; Buttons zentriert (3 Buttons à 100px mit 5px Abstand = 310px, Start bei x15)
    MyGui.Add("Button", "x15 yp+35 w100", L("CaptureWindow", "560")).OnEvent("Click", DoAddRule)
    MyGui.Add("Button", "x120 yp w100", L("CaptureWindow", "565")).OnEvent("Click", DoTestRule)
    MyGui.Add("Button", "x225 yp w100", L("CaptureWindow", "570")).OnEvent("Click", DoCancelToManager)
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
    global CameFromRulesManager
    
    ruleName := MyRuleName.Value
    targetX := Integer(MyEdX.Value)
    targetY := Integer(MyEdY.Value)
    targetW := Integer(MyEdW.Value)
    targetH := Integer(MyEdH.Value)
    matchChoice := MyMatchDDL.Text
    doMaximize := MyMaximizeChk.Value
    
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
    
    if (CameFromRulesManager) {
        CameFromRulesManager := false
        ShowRulesManager()
    }
    SetTimer(CheckWindows, 500)
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
