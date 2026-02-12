//
//  CoverDocumentManager.swift
//  NothingHere
//

import AppKit
import OSLog

private let logger = Logger(subsystem: "boli.NothingHere", category: "CoverDocument")

@Observable
final class CoverDocumentManager {

    static let shared = CoverDocumentManager()

    // MARK: - State

    var openDocumentEnabled: Bool {
        didSet {
            UserDefaults.standard.set(openDocumentEnabled, forKey: "openDocumentEnabled")
        }
    }

    private(set) var documentURL: URL?
    private(set) var documentBookmark: Data?
    private(set) var isDocumentValid = true

    // MARK: - Dependencies

    private let documentService: DocumentLaunchServiceProtocol

    // MARK: - Init

    private init(documentService: DocumentLaunchServiceProtocol = DocumentLaunchService()) {
        self.documentService = documentService
        self.openDocumentEnabled = UserDefaults.standard.bool(forKey: "openDocumentEnabled")
        self.documentBookmark = UserDefaults.standard.data(forKey: "documentBookmark")
        validateDocument()
    }

    // MARK: - Public API

    func pickDocument() {
        documentService.pickDocument { [weak self] url, bookmark in
            guard let self, let url, let bookmark else { return }
            self.documentURL = url
            self.documentBookmark = bookmark
            self.isDocumentValid = true
            UserDefaults.standard.set(bookmark, forKey: "documentBookmark")
            logger.info("Document selected: \(url.lastPathComponent)")
        }
    }

    func removeDocument() {
        documentURL = nil
        documentBookmark = nil
        isDocumentValid = true
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
}
