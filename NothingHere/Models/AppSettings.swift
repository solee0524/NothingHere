//
//  AppSettings.swift
//  NothingHere
//

import Foundation

struct AppSettings {
    var hotkeyKeyCode: UInt16 = 0
    var hotkeyModifiers: UInt32 = 0
    var openDocumentEnabled: Bool = false
    var documentBookmark: Data?
}
