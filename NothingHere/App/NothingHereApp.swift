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
            MenuBarContentView(appDelegate: appDelegate)
        } label: {
            Image(nsImage: menuBarIcon)
        }
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

private struct MenuBarContentView: View {
    let appDelegate: AppDelegate
    @Environment(\.openSettings) private var openSettings

    private var guardMode: GuardModeManager { GuardModeManager.shared }

    var body: some View {
        Group {
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
            Button("Settings\u{2026}") {
                NSApp.setActivationPolicy(.regular)
                NSApp.activate()
                openSettings()
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .onAppear {
            appDelegate.openSettingsAction = { [openSettings] in
                openSettings()
            }
        }
    }
}
