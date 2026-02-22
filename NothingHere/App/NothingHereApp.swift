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
            Button("Setup Guide\u{2026}") {
                appDelegate.showOnboardingWindow()
            }
            Button("Check for Updates\u{2026}") {
                NSApp.setActivationPolicy(.regular)
                NSApp.activate()
                appDelegate.updaterController.checkForUpdates(nil)
            }
            Button("Settings…") {
                appDelegate.openSettingsWindow()
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
