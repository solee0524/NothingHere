//
//  WindowHidingService.swift
//  NothingHere
//

import AppKit
import ApplicationServices
import OSLog

private let logger = Logger(subsystem: "boli.NothingHere", category: "WindowHiding")

protocol WindowHidingServiceProtocol {
    func hideAllWindows(excludePIDs: Set<pid_t>)
}

final class WindowHidingService: WindowHidingServiceProtocol {

    /// Delay before Phase 2 verification + AX cleanup
    private static let phase2Delay: TimeInterval = 0.25
    /// Delay before Phase 3 final verification
    private static let phase3Delay: TimeInterval = 0.5
    /// AX messaging timeout to prevent blocking on unresponsive apps
    private static let axTimeout: Float = 2.0

    func hideAllWindows(excludePIDs: Set<pid_t> = []) {
        logger.info("Hiding all windows — Phase 1: NSRunningApplication.hide()")

        let ownPID = ProcessInfo.processInfo.processIdentifier
        var targetPIDs = Set<pid_t>()

        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular,
                  !app.isTerminated,
                  app.processIdentifier != ownPID else { continue }

            targetPIDs.insert(app.processIdentifier)
            let hidden = app.hide()
            if hidden {
                logger.debug("Phase 1 — hidden app: \(app.localizedName ?? "unknown", privacy: .public)")
            }
        }

        logger.info("Phase 1 complete, sent hide to \(targetPIDs.count) apps")

        // Phase 2/3 target: exclude the cover document's app so it won't be re-hidden
        let verifyPIDs = targetPIDs.subtracting(excludePIDs)

        // Phase 2: verify and force-hide remaining windows via Accessibility API
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.phase2Delay) { [weak self] in
            guard let self else { return }
            let remaining = self.findRemainingVisiblePIDs(in: verifyPIDs)
            if remaining.isEmpty {
                logger.info("Phase 2 — all windows already hidden")
                return
            }
            logger.info("Phase 2 — \(remaining.count) apps still visible, force-hiding via AX")
            for pid in remaining {
                self.forceHideViaAccessibility(pid: pid)
            }

            // Phase 3: final verification pass
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.phase3Delay) { [weak self] in
                guard let self else { return }
                let stillRemaining = self.findRemainingVisiblePIDs(in: verifyPIDs)
                if stillRemaining.isEmpty {
                    logger.info("Phase 3 — all windows hidden")
                } else {
                    logger.warning("Phase 3 — \(stillRemaining.count) apps still visible, retrying AX")
                    for pid in stillRemaining {
                        self.forceHideViaAccessibility(pid: pid)
                    }
                }
            }
        }
    }

    // MARK: - Private

    /// Uses CGWindowList to find PIDs that still have on-screen windows among the target set.
    private func findRemainingVisiblePIDs(in targetPIDs: Set<pid_t>) -> Set<pid_t> {
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[CFString: Any]] else {
            logger.error("CGWindowListCopyWindowInfo returned nil")
            return []
        }

        var visiblePIDs = Set<pid_t>()
        for entry in windowList {
            guard let layer = entry[kCGWindowLayer] as? Int, layer == 0,
                  let pid = entry[kCGWindowOwnerPID] as? pid_t,
                  targetPIDs.contains(pid) else { continue }
            visiblePIDs.insert(pid)
        }
        return visiblePIDs
    }

    /// Synchronously hides an app via Accessibility API (AXUIElement).
    private func forceHideViaAccessibility(pid: pid_t) {
        let appElement = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(appElement, Self.axTimeout)

        let result = AXUIElementSetAttributeValue(
            appElement,
            kAXHiddenAttribute as CFString,
            kCFBooleanTrue
        )

        if result == .success {
            logger.debug("AX force-hidden pid \(pid)")
        } else {
            let appName = NSRunningApplication(processIdentifier: pid)?.localizedName ?? "unknown"
            logger.warning(
                "AX hide failed for \(appName, privacy: .public) (pid \(pid)): error \(result.rawValue)"
            )
        }
    }
}
