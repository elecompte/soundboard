# AHK Soundboard

A lightweight **Windows soundboard written entirely in AutoHotkey v2**. No Electron, Python, soundboard service, or build process.

## Features

- Choose a sound folder from the GUI
- Browse WAV, MP3, M4A, AAC, WMA and FLAC files (actual decoding depends on Windows codecs)
- Double-click to preview sounds; Play and Stop buttons
- Record and assign a Ctrl/Alt/Shift hotkey for each sound
- Hotkeys work globally while the GUI is hidden
- Repeatedly pressing a hotkey restarts its clip
- Save folder and hotkeys in `%APPDATA%\AHKSoundboard\settings.ini`
- Close window to hide in the system tray; right-click tray icon to reopen or exit

## Run

1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Download or clone this repository.
3. Double-click `Soundboard.ahk`.
4. Click **Browse...** and choose the folder containing your audio clips.
5. Select a sound, click the **New hotkey** field, press your shortcut (e.g. **Ctrl+Alt+1**), and click **Assign**.
6. Hide the window; hotkeys continue working.

For your existing example, choose `C:\Users\edlec\Downloads` to pick up `omg.m4a`. It's better to move clips into a dedicated folder once you have several.

## Notes

- The GUI and hotkeys are implemented with standard AutoHotkey v2 functions. Audio uses the Windows Media Player COM component (`WMPlayer.OCX`) in the background, with no player window.
- Windows Media Player's legacy COM component must be available; on Windows N/KN editions you may need Microsoft's Media Feature Pack. M4A codec support depends on Windows installation.
- Hotkey capture uses the built-in AHK Hotkey control (Ctrl, Alt, Shift combinations). Windows-key shortcuts are not captured by that field.
- All sounds play through the **default Windows audio output device**. They are not sent to your microphone.
- Scans only the selected folder, not nested subdirectories. Refresh after adding audio files.
- Settings store names relative to the folder, not absolute filenames. Switching folders intentionally clears assignments to avoid applying old bindings to unrelated sounds.
- This is a source-based AHK script, not a compiled executable.

## Start with Windows (optional)

Press `Win+R`, enter `shell:startup`, and put a shortcut to `Soundboard.ahk` in that folder.

## License

MIT. See [LICENSE](LICENSE).
