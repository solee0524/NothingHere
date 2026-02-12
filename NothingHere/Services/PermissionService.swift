//
//  PermissionService.swift
//  NothingHere
//

import AppKit
import ApplicationServices
import OSLog

private let logger = Logger(subsystem: "boli.NothingHere", category: "Permission")

protocol PermissionServiceProtocol {
    var isAccessibilityGranted: Bool { get }
    func requestAccessibility()
    func openSystemSettings()
}

final class PermissionService: PermissionServiceProtocol {

    var isAccessibilityGranted: Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func requestAccessibility() {
        logger.info("Requesting accessibility permission")
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func openSystemSettings() {
        logger.info("Opening system settings for Accessibility")
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else { return }
        NSWorkspace.shared.open(url)
    }
}
