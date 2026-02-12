//
//  NothingHereApp.swift
//  NothingHere
//
//  Created by libo on 2026/2/9.
//

import Sparkle
import SwiftUI

@main
struct NothingHereApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private var guardMode: GuardModeManager { GuardModeManager.shared }

    var body: some Scene {
        MenuBarExtra {
            Button(guardMode.isArmed ? "Disarm Guard Mode" : "Arm Guard Mode") {
                guardMode.toggle()
            }
            Divider()
            Button("Check for Updates…") {
                appDelegate.updaterController.checkForUpdates(nil)
            }
            SettingsLink {
                Text("Settings…")
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image(systemName: guardMode.isArmed ? "eye.slash.fill" : "eye.slash")
        }
        Settings {
            SettingsView(updater: appDelegate.updaterController.updater)
        }
    }
}
