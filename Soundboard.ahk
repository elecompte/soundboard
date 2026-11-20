#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; A lightweight Windows soundboard powered entirely by AutoHotkey v2.
; Windows Media Player's COM engine provides hidden playback and M4A support.

global ConfigDir := A_AppData "\AHKSoundboard"
global ConfigPath := ConfigDir "\settings.ini"
global SoundDir := A_MyDocuments "\Sounds"
global Bindings := Map()
global ActiveHotkeys := Map()
global SoundFiles := []
global Player := ""
global MainGui := ""
global SoundList := ""
global HotkeyInput := ""
global FolderLabel := ""
global StatusLabel := ""

DirCreate(ConfigDir)
LoadSettings()
BuildGui()
RefreshSounds()

A_IconTip := "AHK Soundboard"
A_TrayMenu.Delete()
A_TrayMenu.Add("Show Soundboard", ShowWindow)
A_TrayMenu.Add("Stop sound", StopSound)
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", ExitAppMenu)
A_TrayMenu.Default := "Show Soundboard"

MainGui.Show()

LoadSettings() {
    global ConfigPath, SoundDir, Bindings
    SoundDir := IniRead(ConfigPath, "General", "Folder", SoundDir)
    count := Integer(IniRead(ConfigPath, "General", "BindingCount", "0"))
    Loop Min(count, 500) {
        name := IniRead(ConfigPath, "Binding" A_Index, "File", "")
        key := IniRead(ConfigPath, "Binding" A_Index, "Hotkey", "")
        if (name != "" && key != "")
            Bindings[StrLower(name)] := key
    }
}

SaveSettings() {
    global ConfigPath, SoundDir, Bindings
    ; Rebuild the file so removed bindings don't return.
    if FileExist(ConfigPath)
        FileDelete(ConfigPath)
    IniWrite(SoundDir, ConfigPath, "General", "Folder")
    IniWrite(Bindings.Count, ConfigPath, "General", "BindingCount")
    index := 0
    for name, key in Bindings {
        index += 1
        IniWrite(name, ConfigPath, "Binding" index, "File")
        IniWrite(key, ConfigPath, "Binding" index, "Hotkey")
    }
}

BuildGui() {
    global MainGui, SoundList, HotkeyInput, FolderLabel, StatusLabel
    MainGui := Gui("+MinSize620x440", "AHK Soundboard")
    MainGui.SetFont("s10", "Segoe UI")
    MainGui.MarginX := 16
    MainGui.MarginY := 14

    MainGui.AddText("xm ym", "Sound folder")
    FolderLabel := MainGui.AddText("xm y+5 w475 h38", "")
    choose := MainGui.AddButton("x+10 yp-3 w100", "Browse...")
    choose.OnEvent("Click", ChooseFolder)

    SoundList := MainGui.AddListView("xm y+12 w575 r12 Grid -Multi", ["Audio file", "Hotkey"])
    SoundList.ModifyCol(1, 375)
    SoundList.ModifyCol(2, 170)
    SoundList.OnEvent("DoubleClick", PlaySelected)
    SoundList.OnEvent("ItemSelect", SelectSound)

    MainGui.AddText("xm y+14", "New hotkey:")
    HotkeyInput := MainGui.AddHotkey("x+12 yp-3 w140")
    assign := MainGui.AddButton("x+10 yp-1 w95", "Assign")
    assign.OnEvent("Click", AssignHotkey)
    clear := MainGui.AddButton("x+8 yp w105", "Clear hotkey")
    clear.OnEvent("Click", ClearHotkey)

    play := MainGui.AddButton("xm y+14 w110", "Play selected")
    play.OnEvent("Click", PlaySelected)
    stop := MainGui.AddButton("x+8 yp w85", "Stop")
    stop.OnEvent("Click", StopSound)
    refresh := MainGui.AddButton("x+8 yp w90", "Refresh")
    refresh.OnEvent("Click", RefreshSounds)
    open := MainGui.AddButton("x+8 yp w125", "Open folder")
    open.OnEvent("Click", OpenFolder)

    StatusLabel := MainGui.AddText("xm y+12 w575", "Ready")
    MainGui.OnEvent("Close", HideWindow)
    MainGui.OnEvent("Escape", HideWindow)
}

RefreshSounds(*) {
    global SoundDir, SoundFiles, SoundList, FolderLabel, Bindings
    FolderLabel.Text := SoundDir
    SoundFiles := []
    SoundList.Delete()

    if !DirExist(SoundDir) {
        SetStatus("Select an existing folder to get started.")
        RemoveActiveHotkeys()
        return
    }

    supported := Map("wav", 1, "mp3", 1, "m4a", 1, "aac", 1, "wma", 1, "flac", 1)
    names := ""
    Loop Files, SoundDir "\*.*", "F" {
        if supported.Has(StrLower(A_LoopFileExt))
            names .= A_LoopFileName "`n"
    }
    if (names != "") {
        names := Sort(RTrim(names, "`n"))
        for name in StrSplit(names, "`n") {
            if (name = "")
                continue
            path := SoundDir "\" name
            SoundFiles.Push({name: name, path: path})
            SoundList.Add("", name, Bindings.Get(StrLower(name), ""))
        }
    }

    RegisterHotkeys()
    SetStatus(SoundFiles.Length " sound(s) found. Double-click to preview.")
}

RegisterHotkeys() {
    global ActiveHotkeys, SoundFiles, Bindings
    RemoveActiveHotkeys()
    for sound in SoundFiles {
        key := Bindings.Get(StrLower(sound.name), "")
        if (key = "")
            continue
        try {
            Hotkey(key, PlaySound.Bind(sound.path), "On")
            ActiveHotkeys[key] := sound.path
        } catch Error as err {
            ; Invalid/unsupported hotkeys are ignored and may be reassigned.
            SetStatus("Could not register " key ": " err.Message)
        }
    }
}

RemoveActiveHotkeys() {
    global ActiveHotkeys
    for key, unused in ActiveHotkeys {
        try Hotkey(key, "Off")
    }
    ActiveHotkeys.Clear()
}

ChooseFolder(*) {
    global SoundDir, Bindings
    folder := DirSelect(DirExist(SoundDir) ? SoundDir : A_MyDocuments, 1, "Choose audio folder")
    if (folder = "" || folder = SoundDir)
        return
    SoundDir := folder
    Bindings.Clear()
    SaveSettings()
    RefreshSounds()
}

GetSelectedSound() {
    global SoundList, SoundFiles
    row := SoundList.GetNext()
    return (row > 0 && row <= SoundFiles.Length) ? SoundFiles[row] : ""
}

SelectSound(control, row, selected) {
    global HotkeyInput, Bindings, SoundFiles
    if (selected && row <= SoundFiles.Length)
        HotkeyInput.Value := Bindings.Get(StrLower(SoundFiles[row].name), "")
}

AssignHotkey(*) {
    global HotkeyInput, Bindings, SoundFiles
    sound := GetSelectedSound()
    if !IsObject(sound) {
        MsgBox("Select a sound first.", "AHK Soundboard", "Icon!")
        return
    }
    key := HotkeyInput.Value
    if (key = "") {
        MsgBox("Press the shortcut inside the New hotkey box first.", "AHK Soundboard", "Icon!")
        return
    }
    for name, existing in Bindings {
        if (existing = key && name != StrLower(sound.name)) {
            MsgBox("That hotkey is already assigned to another sound.", "AHK Soundboard", "Icon!")
            return
        }
    }
    previous := Bindings.Get(StrLower(sound.name), "")
    Bindings[StrLower(sound.name)] := key
    RegisterHotkeys()
    if !ActiveHotkeys.Has(key) {
        if (previous = "")
            Bindings.Delete(StrLower(sound.name))
        else
            Bindings[StrLower(sound.name)] := previous
        RegisterHotkeys()
        MsgBox("Windows or another program may already be using this shortcut.", "Hotkey unavailable", "Icon!")
        return
    }
    SaveSettings()
    RefreshSounds()
    SetStatus(sound.name " assigned to " key)
}

ClearHotkey(*) {
    global Bindings, HotkeyInput
    sound := GetSelectedSound()
    if !IsObject(sound)
        return
    if Bindings.Has(StrLower(sound.name))
        Bindings.Delete(StrLower(sound.name))
    HotkeyInput.Value := ""
    SaveSettings()
    RefreshSounds()
    SetStatus("Cleared hotkey for " sound.name)
}

PlaySelected(*) {
    sound := GetSelectedSound()
    if IsObject(sound)
        PlaySound(sound.path)
}

PlaySound(path, *) {
    global Player
    if !FileExist(path) {
        SetStatus("Missing file: " path)
        return
    }
    try {
        if !IsObject(Player) {
            Player := ComObject("WMPlayer.OCX")
            Player.settings.autoStart := false
        }
        ; Stopping before playing means repeated presses restart the clip.
        Player.controls.stop()
        if (Player.URL != path)
            Player.URL := path
        Player.controls.currentPosition := 0
        Player.controls.play()
        SetStatus("Playing: " SubStr(path, InStr(path, "\",, -1) + 1))
    } catch Error as err {
        SetStatus("Playback failed: " err.Message)
        MsgBox("Windows Media Player's COM component may be unavailable.`n`n" err.Message,
            "Playback error", "Icon!")
    }
}

StopSound(*) {
    global Player
    if IsObject(Player) {
        try Player.controls.stop()
    }
    SetStatus("Stopped")
}

OpenFolder(*) {
    global SoundDir
    if DirExist(SoundDir)
        Run('explorer.exe "' SoundDir '"')
}

SetStatus(message) {
    global StatusLabel
    if IsObject(StatusLabel)
        StatusLabel.Text := message
}

HideWindow(*) {
    global MainGui
    MainGui.Hide()
}

ShowWindow(*) {
    global MainGui
    MainGui.Show()
    WinActivate("ahk_id " MainGui.Hwnd)
}

ExitAppMenu(*) {
    ExitApp()
}
