//
//  AboutTab.swift
//  NothingHere
//

import AppKit
import LucideIcons
import Sparkle
import SwiftUI

// MARK: - Local Color Extension

private extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

// MARK: - Local Lucide Helper

private func lucideIcon(_ image: NSImage, size: CGFloat = 14) -> some View {
    Image(nsImage: image)
        .renderingMode(.template)
        .resizable()
        .frame(width: size, height: size)
}

// MARK: - AboutTab

struct AboutTab: View {
    let updater: SPUUpdater

    @State private var autoCheckForUpdates: Bool
    @State private var copied = false

    init(updater: SPUUpdater) {
        self.updater = updater
        self._autoCheckForUpdates = State(initialValue: updater.automaticallyChecksForUpdates)
    }

    private let email = "helplee2026@gmail.com"
    private let kofiURL = URL(string: "https://ko-fi.com/solee0524")!

    private let accentBlue = Color(hex: 0x4584EE)
    private let subtextGray = Color(hex: 0xAAAAAA)
    private let dividerGray = Color(hex: 0x444444)

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                appInfoSection
                    .padding(.bottom, 32)
                sectionDivider
                    .padding(.bottom, 28)
                updateSection
                    .padding(.bottom, 28)
                sectionDivider
                    .padding(.bottom, 28)
                contactSection
                    .padding(.bottom, 28)
                sectionDivider
                    .padding(.bottom, 28)
                supportSection
            }
            .padding(.top, 60)
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Divider

    private var sectionDivider: some View {
        Rectangle()
            .fill(dividerGray)
            .frame(height: 0.5)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Section Title

    private func sectionTitle(icon: NSImage, title: String) -> some View {
        HStack(spacing: 12) {
            lucideIcon(icon, size: 22)
                .foregroundStyle(accentBlue)
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    // MARK: - App Info

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer().frame(height: 16)

            Text("NothingHere")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.white)

            Spacer().frame(height: 4)

            Text("Version \(appVersion) (Build \(buildNumber))")
                .font(.system(size: 16))
                .foregroundStyle(dividerGray)
        }
    }

    // MARK: - Update

    private var updateSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionTitle(icon: Lucide.hardDriveUpload, title: "Software Update")

            HStack {
                Text("Automatically check for updates")
                    .font(.system(size: 16))
                    .foregroundStyle(subtextGray)
                Spacer()
                Toggle("", isOn: $autoCheckForUpdates)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(accentBlue)
                    .onChange(of: autoCheckForUpdates) { _, newValue in
                        updater.automaticallyChecksForUpdates = newValue
                    }
            }
        }
    }

    // MARK: - Contact

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionTitle(icon: Lucide.mailCheck, title: "Contact Us")

            HStack(spacing: 12) {
                Text(email)
                    .font(.system(size: 16))
                    .foregroundStyle(subtextGray)
                    .textSelection(.enabled)

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(email, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                } label: {
                    lucideIcon(copied ? Lucide.check : Lucide.files, size: 16)
                        .foregroundStyle(accentBlue)
                }
                .buttonStyle(.borderless)
                .help(copied ? "Copied!" : "Copy email address")
            }
        }
    }

    // MARK: - Support

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 22) {
            sectionTitle(icon: Lucide.coins, title: "Support Development")

            Button {
                NSWorkspace.shared.open(kofiURL)
            } label: {
                HStack(spacing: 12) {
                    lucideIcon(Lucide.coffee, size: 20)
                    Text("Buy me a coffee")
                        .font(.system(size: 20, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(accentBlue, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color(hex: 0x4584EE, opacity: 0.3), radius: 8, y: 6)
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
    .preferredColorScheme(.dark)
}
