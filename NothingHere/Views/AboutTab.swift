//
//  AboutTab.swift
//  NothingHere
//

import AppKit
import Sparkle
import SwiftUI

struct AboutTab: View {
    let updater: SPUUpdater

    @State private var autoCheckForUpdates: Bool
    @State private var copied = false

    init(updater: SPUUpdater) {
        self.updater = updater
        self._autoCheckForUpdates = State(initialValue: updater.automaticallyChecksForUpdates)
    }

    private let email = "iblee0524@gmail.com"
    private let kofiURL = URL(string: "https://ko-fi.com/solee0524")!

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                appInfoSection
                Divider().padding(.horizontal, 40)
                updateSection
                Divider().padding(.horizontal, 40)
                contactSection
                Divider().padding(.horizontal, 40)
                supportSection
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - App Info

    private var appInfoSection: some View {
        VStack(spacing: 8) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)

            Text("NothingHere")
                .font(.title2.bold())

            Text("Version \(appVersion) (Build \(buildNumber))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Update

    private var updateSection: some View {
        VStack(spacing: 10) {
            Label("Software Update", systemImage: "arrow.triangle.2.circlepath")
                .font(.headline)

            Toggle("Automatically check for updates", isOn: $autoCheckForUpdates)
                .toggleStyle(.switch)
                .controlSize(.small)
                .onChange(of: autoCheckForUpdates) { _, newValue in
                    updater.automaticallyChecksForUpdates = newValue
                }

            Button("Check for Updates...") {
                updater.checkForUpdates()
            }
            .controlSize(.small)
        }
    }

    // MARK: - Contact

    private var contactSection: some View {
        VStack(spacing: 8) {
            Label("Contact Us", systemImage: "envelope")
                .font(.headline)

            HStack(spacing: 8) {
                Text(email)
                    .font(.body.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(email, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help(copied ? "Copied!" : "Copy email address")
            }
        }
    }

    // MARK: - Support

    private var supportSection: some View {
        VStack(spacing: 8) {
            Label("Support Development", systemImage: "cup.and.saucer")
                .font(.headline)

            Button {
                NSWorkspace.shared.open(kofiURL)
            } label: {
                Image(.kofiButton)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 36)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    AboutTab(updater: SPUStandardUpdaterController(
        startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil
    ).updater)
    .frame(width: 400, height: 500)
}
