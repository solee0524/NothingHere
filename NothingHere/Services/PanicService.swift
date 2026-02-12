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

        // 3. Determine cover document's handler app PID (if running) so Phase 2/3
        //    won't re-hide it after we open the document.
        let defaults = UserDefaults.standard
        let documentEnabled = defaults.bool(forKey: "openDocumentEnabled")
        let documentBookmark = documentEnabled ? defaults.data(forKey: "documentBookmark") : nil

        var coverAppPIDs = Set<pid_t>()
        if let bookmark = documentBookmark,
           let url = documentService.resolveBookmark(bookmark),
           let appURL = NSWorkspace.shared.urlForApplication(toOpen: url),
           let bundle = Bundle(url: appURL),
           let bundleID = bundle.bundleIdentifier,
           let app = NSWorkspace.shared.runningApplications.first(where: {
               $0.bundleIdentifier == bundleID
           }) {
            coverAppPIDs.insert(app.processIdentifier)
            logger.debug("Cover document handler: \(bundleID, privacy: .public) (pid \(app.processIdentifier))")
        }

        // 4. Hide all other app windows (excluding cover document's handler from Phase 2/3)
        windowService.hideAllWindows(excludePIDs: coverAppPIDs)

        // 5. Open cover document if enabled
        if let bookmark = documentBookmark {
            let opened = documentService.openDocument(bookmark: bookmark)
            if !opened {
                logger.warning("Failed to open cover document")
            }
        }

        logger.info("Panic sequence completed")
    }
}
