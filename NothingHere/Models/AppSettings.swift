//
//  AppSettings.swift
//  NothingHere
//

import Foundation

enum CoverActionType: String, CaseIterable {
    case none
    case document
    case app
}

struct AppSettings {
    var hotkeyKeyCode: UInt16 = 0
    var hotkeyModifiers: UInt32 = 0
    var openDocumentEnabled: Bool = false
    var documentBookmark: Data?
}
