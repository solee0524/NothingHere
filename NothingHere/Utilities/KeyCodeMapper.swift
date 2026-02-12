//
//  KeyCodeMapper.swift
//  NothingHere
//

import Carbon.HIToolbox
import AppKit

enum KeyCodeMapper {

    // MARK: - Modifier symbols

    static func modifierSymbols(for flags: UInt32) -> String {
        let nsFlags = NSEvent.ModifierFlags(rawValue: UInt(flags))
        var symbols = ""
        if nsFlags.contains(.control) { symbols += "⌃" }
        if nsFlags.contains(.option) { symbols += "⌥" }
        if nsFlags.contains(.shift) { symbols += "⇧" }
        if nsFlags.contains(.command) { symbols += "⌘" }
        return symbols
    }

    static func modifierSymbolList(for flags: UInt32) -> [String] {
        let nsFlags = NSEvent.ModifierFlags(rawValue: UInt(flags))
        var list: [String] = []
        if nsFlags.contains(.control) { list.append("⌃") }
        if nsFlags.contains(.option) { list.append("⌥") }
        if nsFlags.contains(.shift) { list.append("⇧") }
        if nsFlags.contains(.command) { list.append("⌘") }
        return list
    }

    // MARK: - Key name

    static func keyName(for keyCode: UInt16) -> String {
        keyNames[keyCode] ?? "Key\(keyCode)"
    }

    // MARK: - Human-readable display

    static func displayString(keyCode: UInt16, modifiers: UInt32) -> String {
        modifierSymbols(for: modifiers) + keyName(for: keyCode)
    }

    // MARK: - Conflict detection

    struct ConflictResult {
        let isConflicting: Bool
        let description: String?
    }

    static func checkConflict(keyCode: UInt16, modifiers: UInt32) -> ConflictResult {
        let nsFlags = NSEvent.ModifierFlags(rawValue: UInt(modifiers))
        let key = ConflictKey(keyCode: keyCode, flags: nsFlags.intersection(.deviceIndependentFlagsMask))

        for entry in systemShortcuts {
            if entry.keyCode == key.keyCode && entry.flags == key.flags {
                let display = displayString(keyCode: keyCode, modifiers: modifiers)
                return ConflictResult(
                    isConflicting: true,
                    description: "\(display) is reserved by system (\(entry.name))"
                )
            }
        }
        return ConflictResult(isConflicting: false, description: nil)
    }

    // MARK: - Known system shortcuts

    private struct ConflictKey {
        let keyCode: UInt16
        let flags: NSEvent.ModifierFlags
        var name: String = ""
    }

    private static let cmd = NSEvent.ModifierFlags.command
    private static let cmdShift = NSEvent.ModifierFlags([.command, .shift])
    private static let cmdOpt = NSEvent.ModifierFlags([.command, .option])

    private static let systemShortcuts: [ConflictKey] = [
        // Quit / Close / Hide / Minimize
        ConflictKey(keyCode: UInt16(kVK_ANSI_Q), flags: cmd, name: "Quit"),
        ConflictKey(keyCode: UInt16(kVK_ANSI_W), flags: cmd, name: "Close Window"),
        ConflictKey(keyCode: UInt16(kVK_ANSI_H), flags: cmd, name: "Hide"),
        ConflictKey(keyCode: UInt16(kVK_ANSI_M), flags: cmd, name: "Minimize"),
        // Tab switching
        ConflictKey(keyCode: UInt16(kVK_Tab), flags: cmd, name: "App Switcher"),
        // Copy / Paste / Cut / Undo / Redo / Select All
        ConflictKey(keyCode: UInt16(kVK_ANSI_C), flags: cmd, name: "Copy"),
        ConflictKey(keyCode: UInt16(kVK_ANSI_V), flags: cmd, name: "Paste"),
        ConflictKey(keyCode: UInt16(kVK_ANSI_X), flags: cmd, name: "Cut"),
        ConflictKey(keyCode: UInt16(kVK_ANSI_Z), flags: cmd, name: "Undo"),
        ConflictKey(keyCode: UInt16(kVK_ANSI_Z), flags: cmdShift, name: "Redo"),
        ConflictKey(keyCode: UInt16(kVK_ANSI_A), flags: cmd, name: "Select All"),
        // Save / Print / New / Open
        ConflictKey(keyCode: UInt16(kVK_ANSI_S), flags: cmd, name: "Save"),
        ConflictKey(keyCode: UInt16(kVK_ANSI_P), flags: cmd, name: "Print"),
        ConflictKey(keyCode: UInt16(kVK_ANSI_N), flags: cmd, name: "New"),
        ConflictKey(keyCode: UInt16(kVK_ANSI_O), flags: cmd, name: "Open"),
        // Space (Spotlight)
        ConflictKey(keyCode: UInt16(kVK_Space), flags: cmd, name: "Spotlight"),
        // Hide others
        ConflictKey(keyCode: UInt16(kVK_ANSI_H), flags: cmdOpt, name: "Hide Others"),
    ]

    // MARK: - Key code to name mapping

    private static let keyNames: [UInt16: String] = [
        UInt16(kVK_ANSI_A): "A", UInt16(kVK_ANSI_S): "S",
        UInt16(kVK_ANSI_D): "D", UInt16(kVK_ANSI_F): "F",
        UInt16(kVK_ANSI_H): "H", UInt16(kVK_ANSI_G): "G",
        UInt16(kVK_ANSI_Z): "Z", UInt16(kVK_ANSI_X): "X",
        UInt16(kVK_ANSI_C): "C", UInt16(kVK_ANSI_V): "V",
        UInt16(kVK_ANSI_B): "B", UInt16(kVK_ANSI_Q): "Q",
        UInt16(kVK_ANSI_W): "W", UInt16(kVK_ANSI_E): "E",
        UInt16(kVK_ANSI_R): "R", UInt16(kVK_ANSI_Y): "Y",
        UInt16(kVK_ANSI_T): "T", UInt16(kVK_ANSI_1): "1",
        UInt16(kVK_ANSI_2): "2", UInt16(kVK_ANSI_3): "3",
        UInt16(kVK_ANSI_4): "4", UInt16(kVK_ANSI_6): "6",
        UInt16(kVK_ANSI_5): "5", UInt16(kVK_ANSI_9): "9",
        UInt16(kVK_ANSI_7): "7", UInt16(kVK_ANSI_8): "8",
        UInt16(kVK_ANSI_0): "0", UInt16(kVK_ANSI_O): "O",
        UInt16(kVK_ANSI_U): "U", UInt16(kVK_ANSI_I): "I",
        UInt16(kVK_ANSI_P): "P", UInt16(kVK_ANSI_L): "L",
        UInt16(kVK_ANSI_J): "J", UInt16(kVK_ANSI_K): "K",
        UInt16(kVK_ANSI_N): "N", UInt16(kVK_ANSI_M): "M",
        UInt16(kVK_ANSI_Comma): ",", UInt16(kVK_ANSI_Period): ".",
        UInt16(kVK_ANSI_Slash): "/", UInt16(kVK_ANSI_Semicolon): ";",
        UInt16(kVK_ANSI_Quote): "'", UInt16(kVK_ANSI_Backslash): "\\",
        UInt16(kVK_ANSI_LeftBracket): "[", UInt16(kVK_ANSI_RightBracket): "]",
        UInt16(kVK_ANSI_Grave): "`", UInt16(kVK_ANSI_Minus): "-",
        UInt16(kVK_ANSI_Equal): "=",
        UInt16(kVK_Return): "↩", UInt16(kVK_Tab): "⇥",
        UInt16(kVK_Space): "Space", UInt16(kVK_Delete): "⌫",
        UInt16(kVK_Escape): "⎋", UInt16(kVK_ForwardDelete): "⌦",
        UInt16(kVK_LeftArrow): "←", UInt16(kVK_RightArrow): "→",
        UInt16(kVK_UpArrow): "↑", UInt16(kVK_DownArrow): "↓",
        UInt16(kVK_Home): "↖", UInt16(kVK_End): "↘",
        UInt16(kVK_PageUp): "⇞", UInt16(kVK_PageDown): "⇟",
        UInt16(kVK_F1): "F1", UInt16(kVK_F2): "F2",
        UInt16(kVK_F3): "F3", UInt16(kVK_F4): "F4",
        UInt16(kVK_F5): "F5", UInt16(kVK_F6): "F6",
        UInt16(kVK_F7): "F7", UInt16(kVK_F8): "F8",
        UInt16(kVK_F9): "F9", UInt16(kVK_F10): "F10",
        UInt16(kVK_F11): "F11", UInt16(kVK_F12): "F12",
    ]
}
