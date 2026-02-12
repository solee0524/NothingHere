//
//  AppDelegate.swift
//  NothingHere
//

import AppKit
import OSLog
import Sparkle

private let logger = Logger(subsystem: "boli.NothingHere", category: "AppDelegate")

final class AppDelegate: NSObject, NSApplicationDelegate {

    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    private let hotkeyService = HotkeyService()
    private let panicService = PanicService()

    private var lastRegisteredKeyCode: UInt16 = 0
    private var lastRegisteredModifiers: UInt32 = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Application did finish launching")
        NSApp.setActivationPolicy(.accessory)

        // Wire hotkey to panic
        hotkeyService.onHotkeyTriggered = { [weak self] in
            self?.panicService.execute()
        }

        // Wire guard mode to panic
        GuardModeManager.shared.onGuardTriggered = { [weak self] in
            self?.panicService.execute()
        }

        // Register saved hotkey
        registerHotkeyFromDefaults()

        // Window tracking for dynamic Dock icon
        NotificationCenter.default.addObserver(
            self, selector: #selector(windowDidBecomeKey(_:)),
            name: NSWindow.didBecomeKeyNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification, object: nil
        )

        // Re-register hotkey when settings change
        NotificationCenter.default.addObserver(
            self, selector: #selector(hotkeySettingsChanged),
            name: UserDefaults.didChangeNotification, object: nil
        )

        // Pause/resume global hotkey during recording
        NotificationCenter.default.addObserver(
            self, selector: #selector(hotkeyRecordingDidStart),
            name: .hotkeyRecordingDidStart, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(hotkeyRecordingDidEnd),
            name: .hotkeyRecordingDidEnd, object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyService.unregister()
        GuardModeManager.shared.disarm()
        logger.info("Application will terminate")
    }

    private func registerHotkeyFromDefaults() {
        let keyCode = UInt16(UserDefaults.standard.integer(forKey: "hotkeyKeyCode"))
        let modifiers = UInt32(UserDefaults.standard.integer(forKey: "hotkeyModifiers"))

        guard keyCode != lastRegisteredKeyCode || modifiers != lastRegisteredModifiers else { return }

        lastRegisteredKeyCode = keyCode
        lastRegisteredModifiers = modifiers

        if keyCode != 0 || modifiers != 0 {
            hotkeyService.register(keyCode: keyCode, modifiers: modifiers)
        } else {
            hotkeyService.unregister()
        }
    }

    @objc private func hotkeySettingsChanged() {
        registerHotkeyFromDefaults()
    }

    @objc private func hotkeyRecordingDidStart() {
        hotkeyService.unregister()
        logger.info("Global hotkey paused for recording")
    }

    @objc private func hotkeyRecordingDidEnd() {
        lastRegisteredKeyCode = 0
        lastRegisteredModifiers = 0
        registerHotkeyFromDefaults()
        logger.info("Global hotkey resumed after recording")
    }

    @objc private func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window.level == .normal else { return }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }

    @objc private func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.async {
            let hasVisibleWindows = NSApp.windows.contains {
                $0.isVisible && $0.level == .normal && !$0.isMiniaturized
            }
            if !hasVisibleWindows {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
}
