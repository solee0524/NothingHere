//
//  SettingsViewModel.swift
//  NothingHere
//

import AppKit
import Carbon.HIToolbox
import Combine
import OSLog

private let logger = Logger(subsystem: "boli.NothingHere", category: "SettingsViewModel")

@Observable
final class SettingsViewModel {

    // MARK: - Permission state

    private(set) var isAccessibilityGranted = false

    // MARK: - Hotkey display state

    private(set) var currentHotkeyDisplay: String?
    private(set) var currentModifierSymbols: [String] = []
    private(set) var currentKeyName: String?

    // MARK: - Hotkey recording state

    var showRecordingPopover = false
    private(set) var liveModifierSymbols: [String] = []
    private(set) var pendingKeyCode: UInt16?
    private(set) var pendingModifiers: UInt32?
    private(set) var pendingDisplay: String?
    private(set) var pendingConflict: String?
    private(set) var isPendingReady = false
    private(set) var hotkeyConflictMessage: String?

    // MARK: - Document state

    var openDocumentEnabled: Bool {
        didSet {
            UserDefaults.standard.set(openDocumentEnabled, forKey: "openDocumentEnabled")
            if openDocumentEnabled && documentBookmark == nil {
                DispatchQueue.main.async { [weak self] in
                    self?.pickDocument()
                }
            } else if !openDocumentEnabled {
                removeDocument()
            }
        }
    }
    private(set) var documentURL: URL?
    private(set) var isDocumentValid = true
    private(set) var documentBookmark: Data?

    // MARK: - Services

    private let permissionService: PermissionServiceProtocol
    private let documentService: DocumentLaunchServiceProtocol

    // MARK: - Internal

    private var pollTimer: Timer?
    private var debounceTimer: Timer?
    private var hotkeyKeyCode: UInt16
    private var hotkeyModifiers: UInt32

    // MARK: - Init

    init(
        permissionService: PermissionServiceProtocol = PermissionService(),
        documentService: DocumentLaunchServiceProtocol = DocumentLaunchService()
    ) {
        self.permissionService = permissionService
        self.documentService = documentService

        self.hotkeyKeyCode = UInt16(UserDefaults.standard.integer(forKey: "hotkeyKeyCode"))
        self.hotkeyModifiers = UInt32(UserDefaults.standard.integer(forKey: "hotkeyModifiers"))
        self.openDocumentEnabled = UserDefaults.standard.bool(forKey: "openDocumentEnabled")
        self.documentBookmark = UserDefaults.standard.data(forKey: "documentBookmark")

        loadHotkeyDisplay()
        validateDocument()
    }

    // MARK: - Lifecycle

    func onAppear() {
        isAccessibilityGranted = permissionService.isAccessibilityGranted
        startPolling()
        validateDocument()
    }

    func onDisappear() {
        stopPolling()
        if showRecordingPopover {
            cancelRecording()
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
            self.isAccessibilityGranted = self.permissionService.isAccessibilityGranted
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    // MARK: - Hotkey recording

    func startRecordingHotkey() {
        hotkeyConflictMessage = nil
        clearPendingState()
        liveModifierSymbols = []
        showRecordingPopover = true

        NotificationCenter.default.post(name: .hotkeyRecordingDidStart, object: nil)

        logger.info("Started hotkey recording")
    }

    func cancelRecording() {
        invalidateDebounceTimer()
        clearPendingState()
        liveModifierSymbols = []
        showRecordingPopover = false

        NotificationCenter.default.post(name: .hotkeyRecordingDidEnd, object: nil)
        logger.info("Hotkey recording cancelled")
    }

    func resetRecording() {
        clearPendingState()
        liveModifierSymbols = []
        logger.info("Hotkey recording reset to initial state")
    }

    func confirmHotkey() {
        guard let keyCode = pendingKeyCode, let modifiers = pendingModifiers else { return }

        hotkeyKeyCode = keyCode
        hotkeyModifiers = modifiers
        UserDefaults.standard.set(Int(keyCode), forKey: "hotkeyKeyCode")
        UserDefaults.standard.set(Int(modifiers), forKey: "hotkeyModifiers")

        hotkeyConflictMessage = nil
        loadHotkeyDisplay()
        invalidateDebounceTimer()
        clearPendingState()
        liveModifierSymbols = []
        showRecordingPopover = false

        NotificationCenter.default.post(name: .hotkeyRecordingDidEnd, object: nil)

        let display = currentHotkeyDisplay ?? "unknown"
        logger.info("Hotkey saved: \(display)")
    }

    func handleKeyEvent(_ event: NSEvent) {
        let keyCode = event.keyCode

        // Escape cancels recording
        if keyCode == UInt16(kVK_Escape) {
            cancelRecording()
            return
        }

        // Require at least one modifier key
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let hasModifier = modifiers.contains(.command) || modifiers.contains(.control)
            || modifiers.contains(.option)
        guard hasModifier else { return }

        let modifierRaw = UInt32(modifiers.rawValue)

        // Store pending combination
        pendingKeyCode = keyCode
        pendingModifiers = modifierRaw
        pendingDisplay = KeyCodeMapper.displayString(keyCode: keyCode, modifiers: modifierRaw)
        pendingConflict = nil
        isPendingReady = false

        // Update live display to show full combination
        liveModifierSymbols = KeyCodeMapper.modifierSymbolList(for: modifierRaw)
            + [KeyCodeMapper.keyName(for: keyCode)]

        // Start debounce timer for conflict check
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.checkPendingConflict()
        }
    }

    func handleFlagsChanged(_ event: NSEvent) {
        // Only update live modifiers if we don't have a pending combination yet
        guard pendingKeyCode == nil else { return }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        liveModifierSymbols = KeyCodeMapper.modifierSymbolList(for: UInt32(modifiers.rawValue))
    }

    private func checkPendingConflict() {
        guard let keyCode = pendingKeyCode, let modifiers = pendingModifiers else { return }

        let conflict = KeyCodeMapper.checkConflict(keyCode: keyCode, modifiers: modifiers)
        if conflict.isConflicting {
            pendingConflict = conflict.description
            isPendingReady = false
            logger.warning("Hotkey conflict detected: \(conflict.description ?? "")")
        } else {
            pendingConflict = nil
            isPendingReady = true
        }
    }

    private func invalidateDebounceTimer() {
        debounceTimer?.invalidate()
        debounceTimer = nil
    }

    private func clearPendingState() {
        pendingKeyCode = nil
        pendingModifiers = nil
        pendingDisplay = nil
        pendingConflict = nil
        isPendingReady = false
    }

    private func loadHotkeyDisplay() {
        if hotkeyKeyCode == 0 && hotkeyModifiers == 0 {
            currentHotkeyDisplay = nil
            currentModifierSymbols = []
            currentKeyName = nil
        } else {
            currentHotkeyDisplay = KeyCodeMapper.displayString(
                keyCode: hotkeyKeyCode,
                modifiers: hotkeyModifiers
            )
            currentModifierSymbols = KeyCodeMapper.modifierSymbolList(for: hotkeyModifiers)
            currentKeyName = KeyCodeMapper.keyName(for: hotkeyKeyCode)
        }
    }

    // MARK: - Document

    func pickDocument() {
        documentService.pickDocument { [weak self] url, bookmark in
            guard let self else { return }
            if let url, let bookmark {
                self.documentURL = url
                self.documentBookmark = bookmark
                self.isDocumentValid = true
                UserDefaults.standard.set(bookmark, forKey: "documentBookmark")
                logger.info("Document selected: \(url.lastPathComponent)")
            } else {
                // User cancelled — revert toggle if no existing bookmark
                if self.documentBookmark == nil {
                    self.openDocumentEnabled = false
                }
            }
        }
    }

    func removeDocument() {
        documentURL = nil
        documentBookmark = nil
        isDocumentValid = true
        UserDefaults.standard.removeObject(forKey: "documentBookmark")
        logger.info("Document removed")
    }

    private func validateDocument() {
        guard let bookmark = documentBookmark else {
            isDocumentValid = true
            return
        }

        if documentService.validateFile(bookmark: bookmark) {
            documentURL = documentService.resolveBookmark(bookmark)
            isDocumentValid = true
        } else {
            logger.warning("Document is no longer available, clearing bookmark")
            documentURL = nil
            documentBookmark = nil
            isDocumentValid = false
            openDocumentEnabled = false
            UserDefaults.standard.removeObject(forKey: "documentBookmark")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let hotkeyRecordingDidStart = Notification.Name("HotkeyRecordingDidStart")
    static let hotkeyRecordingDidEnd = Notification.Name("HotkeyRecordingDidEnd")
}
