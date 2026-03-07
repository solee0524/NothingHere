//
//  PanicService.swift
//  NothingHere
//

import AppKit
import OSLog

private let logger = Logger(subsystem: "boli.NothingHere", category: "PanicService")

protocol PanicServiceProtocol {
    func execute()
}

final class PanicService: PanicServiceProtocol {

    private let windowService: WindowHidingServiceProtocol
    private let mediaService: MediaControlServiceProtocol
    private let documentService: DocumentLaunchServiceProtocol

    private var lastExecutionTime: Date = .distantPast
    private static let debounceInterval: TimeInterval = 1.0

    init(
        windowService: WindowHidingServiceProtocol = WindowHidingService(),
        mediaService: MediaControlServiceProtocol = MediaControlService(),
        documentService: DocumentLaunchServiceProtocol = DocumentLaunchService()
    ) {
        self.windowService = windowService
        self.mediaService = mediaService
        self.documentService = documentService
    }

    func execute() {
        let now = Date()
        guard now.timeIntervalSince(lastExecutionTime) > Self.debounceInterval else {
            logger.info("Panic sequence debounced")
            return
        }
        lastExecutionTime = now

        logger.info("Panic sequence triggered")

        // 1. Pause media FIRST (before hiding, so Automation permission dialogs are visible)
        mediaService.pauseAllMedia()

        // 2. Close NothingHere's own windows (settings window etc.)
        for window in NSApp.windows where window.isVisible && window.level == .normal {
            window.close()
        }

        // 3. Collect all PIDs that should be excluded from hiding
        var excludePIDs = Set<pid_t>()

        // 3a. Whitelist PIDs
        let whitelistPIDs = WhitelistManager.shared.resolveRunningPIDs()
        excludePIDs.formUnion(whitelistPIDs)
        if !whitelistPIDs.isEmpty {
            logger.debug("Whitelist excludes \(whitelistPIDs.count) PIDs")
        }

        // 3b. Cover action — determine what to open and its PID
        let coverAction = CoverActionManager.shared
        let actionType = coverAction.coverActionType

        switch actionType {
        case .document:
            if let bookmark = coverAction.documentBookmark,
               let url = documentService.resolveBookmark(bookmark),
               let appURL = NSWorkspace.shared.urlForApplication(toOpen: url),
               let bundle = Bundle(url: appURL),
               let bundleID = bundle.bundleIdentifier,
               let app = NSWorkspace.shared.runningApplications.first(where: {
                   $0.bundleIdentifier == bundleID
               }) {
                excludePIDs.insert(app.processIdentifier)
                logger.debug("Cover document handler: \(bundleID, privacy: .public) (pid \(app.processIdentifier))")
            }

        case .app:
            if let bundleID = coverAction.coverAppBundleID,
               let app = NSWorkspace.shared.runningApplications.first(where: {
                   $0.bundleIdentifier == bundleID
               }) {
                excludePIDs.insert(app.processIdentifier)
                logger.debug("Cover app: \(bundleID, privacy: .public) (pid \(app.processIdentifier))")
            }

        case .none:
            break
        }

        // 4. Hide all other app windows
        windowService.hideAllWindows(excludePIDs: excludePIDs)

        // 5. Open cover action
        switch actionType {
        case .document:
            if let bookmark = coverAction.documentBookmark {
                let opened = documentService.openDocument(bookmark: bookmark)
                if !opened {
                    logger.warning("Failed to open cover document")
                }
            }

        case .app:
            if let bundleID = coverAction.coverAppBundleID {
                let opened = documentService.openApp(bundleIdentifier: bundleID)
                if !opened {
                    logger.warning("Failed to open cover app")
                }
            }

        case .none:
            break
        }

        logger.info("Panic sequence completed")
    }
}
