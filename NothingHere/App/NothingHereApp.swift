//
//  NothingHereApp.swift
//  NothingHere
//
//  Created by libo on 2026/2/9.
//

import LucideIcons
import Sparkle
import SwiftUI

@main
struct NothingHereApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private var guardMode: GuardModeManager { GuardModeManager.shared }

    var body: some Scene {
        MenuBarExtra {
            MenuBarPopoverView(appDelegate: appDelegate)
        } label: {
            Image(nsImage: menuBarIcon)
        }
        .menuBarExtraStyle(.window)
        Settings {
            SettingsView(updater: appDelegate.updaterController.updater)
        }
    }

    private var menuBarIcon: NSImage {
        let icon = guardMode.isArmed ? Lucide.shieldAlert : Lucide.eyeOff
        icon.isTemplate = true
        icon.size = NSSize(width: 18, height: 18)
        return icon
    }
}
