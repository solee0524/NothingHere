//
//  AppDelegate.swift
//  NothingHere
//

import ApplicationServices
import AppKit
import OSLog
import Sparkle
import SwiftUI

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

    private var onboardingWindow: NSWindow?
    var openSettingsAction: (() -> Void)?

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

        // Permission needed notification — open Settings
        NotificationCenter.default.addObserver(
            self, selector: #selector(handlePermissionNeeded),
            name: .accessibilityPermissionNeeded, object: nil
        )

        // Re-register hotkey when accessibility permission is granted
        NotificationCenter.default.addObserver(
            self, selector: #selector(handlePermissionGranted),
            name: .accessibilityPermissionGranted, object: nil
        )

        // Show onboarding if first launch, also open Settings alongside
        if !OnboardingViewModel.hasCompletedOnboarding {
            DispatchQueue.main.async { [weak self] in
                self?.openSettingsWindow()
                self?.showOnboardingWindow()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyService.unregister()
        GuardModeManager.shared.disarm()
        logger.info("Application will terminate")
    }

    // MARK: - Settings Window

    func openSettingsWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        if let action = openSettingsAction {
            action()
        } else {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
    }

    // MARK: - Onboarding Window

    func showOnboardingWindow() {
        NSApp.setActivationPolicy(.regular)

        // If already showing, just bring to front
        if let existing = onboardingWindow, existing.isVisible {
            existing.orderFrontRegardless()
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        let viewModel = OnboardingViewModel()
        viewModel.onComplete = { [weak self] in
            self?.onboardingWindow?.close()
        }

        let hostingView = NSHostingView(rootView: OnboardingView(viewModel: viewModel))
        hostingView.frame = NSRect(x: 0, y: 0, width: 500, height: 460)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 460),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false

        onboardingWindow = window
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    // MARK: - Hotkey Management

    private func registerHotkeyFromDefaults() {
        let keyCode = UInt16(UserDefaults.standard.integer(forKey: "hotkeyKeyCode"))
        let modifiers = UInt32(UserDefaults.standard.integer(forKey: "hotkeyModifiers"))

        guard keyCode != lastRegisteredKeyCode || modifiers != lastRegisteredModifiers else { return }

        lastRegisteredKeyCode = keyCode
        lastRegisteredModifiers = modifiers

        if keyCode != 0 || modifiers != 0 {
            // Only create event tap if accessibility is already granted,
            // to avoid triggering the system permission dialog on launch.
            guard AXIsProcessTrusted() else {
                logger.info("Skipping hotkey registration — accessibility not yet granted")
                return
            }
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

    // MARK: - Permission Needed

    @objc private func handlePermissionNeeded() {
        openSettingsWindow()
    }

    @objc private func handlePermissionGranted() {
        // Reset cached state so registerHotkeyFromDefaults re-evaluates
        lastRegisteredKeyCode = 0
        lastRegisteredModifiers = 0
        registerHotkeyFromDefaults()
        logger.info("Accessibility granted — registering hotkey")
    }

    // MARK: - Window Tracking

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
