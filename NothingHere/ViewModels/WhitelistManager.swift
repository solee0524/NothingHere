//
//  WhitelistManager.swift
//  NothingHere
//

import AppKit
import OSLog
import UniformTypeIdentifiers

private let logger = Logger(subsystem: "boli.NothingHere", category: "Whitelist")

@Observable
final class WhitelistManager {

    static let shared = WhitelistManager()

    // MARK: - State

    private(set) var apps: [WhitelistedApp] = []

    // MARK: - Init

    private init() {
        loadApps()
    }

    // MARK: - Public API

    func pickApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Select an app to whitelist"

        panel.begin { [weak self] response in
            guard let self, response == .OK, let url = panel.url else { return }
            guard let bundle = Bundle(url: url),
                  let bundleID = bundle.bundleIdentifier else {
                logger.warning("Selected item is not a valid app bundle")
                return
            }

            // Deduplicate by bundle ID
            if self.apps.contains(where: { $0.bundleIdentifier == bundleID }) {
                logger.info("App already whitelisted: \(bundleID, privacy: .public)")
                return
            }

            let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? url.deletingPathExtension().lastPathComponent

            let app = WhitelistedApp(bundleIdentifier: bundleID, displayName: displayName)
            self.apps.append(app)
            self.saveApps()
            logger.info("Whitelisted app: \(displayName, privacy: .public) (\(bundleID, privacy: .public))")
        }
    }

    func removeApp(bundleIdentifier: String) {
        apps.removeAll { $0.bundleIdentifier == bundleIdentifier }
        saveApps()
        logger.info("Removed whitelisted app: \(bundleIdentifier, privacy: .public)")
    }

    /// Resolves whitelisted bundle IDs to PIDs of currently running apps.
    func resolveRunningPIDs() -> Set<pid_t> {
        let whitelistedBundleIDs = Set(apps.map(\.bundleIdentifier))
        var pids = Set<pid_t>()
        for app in NSWorkspace.shared.runningApplications {
            if let bundleID = app.bundleIdentifier, whitelistedBundleIDs.contains(bundleID) {
                pids.insert(app.processIdentifier)
            }
        }
        return pids
    }

    // MARK: - Persistence

    private func loadApps() {
        guard let data = UserDefaults.standard.data(forKey: "whitelistedApps") else { return }
        do {
            apps = try JSONDecoder().decode([WhitelistedApp].self, from: data)
            logger.info("Loaded \(self.apps.count) whitelisted apps")
        } catch {
            logger.error("Failed to decode whitelisted apps: \(error.localizedDescription)")
        }
    }

    private func saveApps() {
        do {
            let data = try JSONEncoder().encode(apps)
            UserDefaults.standard.set(data, forKey: "whitelistedApps")
        } catch {
            logger.error("Failed to encode whitelisted apps: \(error.localizedDescription)")
        }
    }
}
