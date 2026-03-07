//
//  DocumentLaunchService.swift
//  NothingHere
//

import AppKit
import OSLog

private let logger = Logger(subsystem: "boli.NothingHere", category: "DocumentLaunch")

protocol DocumentLaunchServiceProtocol {
    func openDocument(bookmark: Data) -> Bool
    func pickDocument(completion: @escaping (URL?, Data?) -> Void)
    func resolveBookmark(_ data: Data) -> URL?
    func validateFile(bookmark: Data) -> Bool
    func openApp(bundleIdentifier: String) -> Bool
}

final class DocumentLaunchService: DocumentLaunchServiceProtocol {

    func openDocument(bookmark: Data) -> Bool {
        guard let url = resolveBookmark(bookmark) else {
            logger.error("Failed to resolve bookmark for document opening")
            return false
        }

        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        NSWorkspace.shared.open(url)
        logger.info("Opened document: \(url.lastPathComponent)")
        return true
    }

    func pickDocument(completion: @escaping (URL?, Data?) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a file to open when panic button is pressed"

        panel.begin { response in
            guard response == .OK, let url = panel.url else {
                logger.info("Document selection cancelled")
                completion(nil, nil)
                return
            }

            do {
                let bookmarkData = try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                logger.info("Created security-scoped bookmark for: \(url.lastPathComponent)")
                completion(url, bookmarkData)
            } catch {
                logger.error("Failed to create bookmark: \(error.localizedDescription)")
                completion(nil, nil)
            }
        }
    }

    func resolveBookmark(_ data: Data) -> URL? {
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                logger.warning("Bookmark is stale for: \(url.lastPathComponent)")
            }
            return url
        } catch {
            logger.error("Failed to resolve bookmark: \(error.localizedDescription)")
            return nil
        }
    }

    func validateFile(bookmark: Data) -> Bool {
        guard let url = resolveBookmark(bookmark) else { return false }

        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        let exists = FileManager.default.fileExists(atPath: url.path)
        if !exists {
            logger.warning("Document no longer exists: \(url.path)")
        }
        return exists
    }

    func openApp(bundleIdentifier: String) -> Bool {
        guard let appURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: bundleIdentifier
        ) else {
            logger.error("No app found for bundle ID: \(bundleIdentifier, privacy: .public)")
            return false
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { app, error in
            if let error {
                logger.error("Failed to open app \(bundleIdentifier, privacy: .public): \(error.localizedDescription)")
            } else if let app {
                logger.info("Opened app: \(app.localizedName ?? bundleIdentifier, privacy: .public)")
            }
        }
        return true
    }
}
