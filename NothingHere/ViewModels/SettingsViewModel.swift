//
//  SettingsViewModel.swift
//  NothingHere
//

import AppKit
import Combine
import OSLog

private let logger = Logger(subsystem: "boli.NothingHere", category: "SettingsViewModel")

@Observable
final class SettingsViewModel {

    // MARK: - Permission state

    private(set) var isAccessibilityGranted = false

    // MARK: - Hotkey (delegated to HotkeyRecordingManager)

    let hotkeyRecorder = HotkeyRecordingManager()

    // MARK: - Document (delegated to CoverDocumentManager)

    let documentManager = CoverDocumentManager.shared

    // MARK: - Services

    private let permissionService: PermissionServiceProtocol

    // MARK: - Internal

    private var pollTimer: Timer?

    // MARK: - Init

    init(
        permissionService: PermissionServiceProtocol = PermissionService()
    ) {
        self.permissionService = permissionService
    }

    // MARK: - Lifecycle

    func onAppear() {
        isAccessibilityGranted = permissionService.isAccessibilityGranted
        startPolling()
        documentManager.validateDocument()
    }

    func onDisappear() {
        stopPolling()
        if hotkeyRecorder.showRecordingPopover {
            hotkeyRecorder.cancelRecording()
        }
    }

    // MARK: - Permission

    func grantPermission() {
        permissionService.requestAccessibility()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            self.isAccessibilityGranted = self.permissionService.isAccessibilityGranted
        }
    }

    func openPermissionSettings() {
        permissionService.openSystemSettings()
    }

    private func startPolling() {
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let wasGranted = self.isAccessibilityGranted
            self.isAccessibilityGranted = self.permissionService.isAccessibilityGranted
            if !wasGranted && self.isAccessibilityGranted {
                NotificationCenter.default.post(name: .accessibilityPermissionGranted, object: nil)
            }
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let hotkeyRecordingDidStart = Notification.Name("HotkeyRecordingDidStart")
    static let hotkeyRecordingDidEnd = Notification.Name("HotkeyRecordingDidEnd")
    static let accessibilityPermissionNeeded = Notification.Name("AccessibilityPermissionNeeded")
    static let accessibilityPermissionGranted = Notification.Name("AccessibilityPermissionGranted")
}
