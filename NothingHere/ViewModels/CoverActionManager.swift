//
//  CoverActionManager.swift
//  NothingHere
//

import AppKit
import OSLog
import UniformTypeIdentifiers

private let logger = Logger(subsystem: "boli.NothingHere", category: "CoverAction")

@Observable
final class CoverActionManager {

    static let shared = CoverActionManager()

    // MARK: - Cover Action Type

    var coverActionType: CoverActionType {
        didSet {
            UserDefaults.standard.set(coverActionType.rawValue, forKey: "coverActionType")
        }
    }

    // MARK: - Document State (preserved from CoverDocumentManager)

    private(set) var documentURL: URL?
    private(set) var documentBookmark: Data?
    private(set) var isDocumentValid = true

    // MARK: - App State

    private(set) var coverAppBundleID: String?
    private(set) var coverAppDisplayName: String?
    private(set) var coverAppURL: URL?
    private(set) var isCoverAppValid = true

    // MARK: - Dependencies

    private let documentService: DocumentLaunchServiceProtocol

    // MARK: - Init

    private init(documentService: DocumentLaunchServiceProtocol = DocumentLaunchService()) {
        self.documentService = documentService

        // Migration: old openDocumentEnabled → coverActionType
        let defaults = UserDefaults.standard
        if let rawType = defaults.string(forKey: "coverActionType"),
           let actionType = CoverActionType(rawValue: rawType) {
            self.coverActionType = actionType
        } else if defaults.object(forKey: "openDocumentEnabled") != nil {
            // Migrate from old bool setting
            let wasEnabled = defaults.bool(forKey: "openDocumentEnabled")
            self.coverActionType = wasEnabled ? .document : .none
            defaults.set(self.coverActionType.rawValue, forKey: "coverActionType")
            defaults.removeObject(forKey: "openDocumentEnabled")
            logger.info("Migrated openDocumentEnabled=\(wasEnabled) to coverActionType=\(self.coverActionType.rawValue)")
        } else {
            self.coverActionType = .none
        }

        // Load document bookmark
        self.documentBookmark = defaults.data(forKey: "documentBookmark")
        validateDocument()

        // Load app settings
        self.coverAppBundleID = defaults.string(forKey: "coverAppBundleID")
        self.coverAppDisplayName = defaults.string(forKey: "coverAppDisplayName")
        validateApp()
    }

    // MARK: - Document API

    func pickDocument() {
        documentService.pickDocument { [weak self] url, bookmark in
            guard let self, let url, let bookmark else { return }
            self.clearAppData()
            self.documentURL = url
            self.documentBookmark = bookmark
            self.isDocumentValid = true
            self.coverActionType = .document
            UserDefaults.standard.set(bookmark, forKey: "documentBookmark")
            logger.info("Document selected: \(url.lastPathComponent)")
        }
    }

    func removeDocument() {
        documentURL = nil
        documentBookmark = nil
        isDocumentValid = true
        coverActionType = .none
        UserDefaults.standard.removeObject(forKey: "documentBookmark")
        logger.info("Document removed")
    }

    func validateDocument() {
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
            UserDefaults.standard.removeObject(forKey: "documentBookmark")
        }
    }

    // MARK: - App API

    func pickApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Select an app to open when panic triggers"

        panel.begin { [weak self] response in
            guard let self, response == .OK, let url = panel.url else { return }
            guard let bundle = Bundle(url: url),
                  let bundleID = bundle.bundleIdentifier else {
                logger.warning("Selected item is not a valid app bundle")
                return
            }

            let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? url.deletingPathExtension().lastPathComponent

            self.clearDocumentData()
            self.coverAppBundleID = bundleID
            self.coverAppDisplayName = displayName
            self.coverAppURL = url
            self.isCoverAppValid = true
            self.coverActionType = .app

            let defaults = UserDefaults.standard
            defaults.set(bundleID, forKey: "coverAppBundleID")
            defaults.set(displayName, forKey: "coverAppDisplayName")
            logger.info("Cover app selected: \(displayName, privacy: .public) (\(bundleID, privacy: .public))")
        }
    }

    func removeApp() {
        coverAppBundleID = nil
        coverAppDisplayName = nil
        coverAppURL = nil
        isCoverAppValid = true
        coverActionType = .none

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "coverAppBundleID")
        defaults.removeObject(forKey: "coverAppDisplayName")
        logger.info("Cover app removed")
    }

    func validateApp() {
        guard let bundleID = coverAppBundleID else {
            isCoverAppValid = true
            return
        }

        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            coverAppURL = appURL
            isCoverAppValid = true
        } else {
            logger.warning("Cover app no longer available: \(bundleID, privacy: .public)")
            isCoverAppValid = false
        }
    }

    // MARK: - Toggle Support

    var isEnabled: Bool {
        get { coverActionType != .none }
        set {
            if newValue {
                // Restore based on whichever data exists (single-slot, so only one can exist)
                if documentBookmark != nil {
                    coverActionType = .document
                } else if coverAppBundleID != nil {
                    coverActionType = .app
                }
                // If neither exists, stay .none — user needs to pick something
            } else {
                coverActionType = .none
            }
        }
    }

    // MARK: - Mutual Exclusion

    private func clearDocumentData() {
        documentURL = nil
        documentBookmark = nil
        isDocumentValid = true
        UserDefaults.standard.removeObject(forKey: "documentBookmark")
        logger.info("Document data cleared (mutual exclusion)")
    }

    private func clearAppData() {
        coverAppBundleID = nil
        coverAppDisplayName = nil
        coverAppURL = nil
        isCoverAppValid = true
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "coverAppBundleID")
        defaults.removeObject(forKey: "coverAppDisplayName")
        logger.info("App data cleared (mutual exclusion)")
    }
}
