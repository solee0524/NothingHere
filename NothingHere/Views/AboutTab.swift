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
                    .padding(.bottom, 24)
                sectionDivider
                    .padding(.bottom, 20)
                updateSection
                    .padding(.bottom, 20)
                sectionDivider
                    .padding(.bottom, 20)
                contactSection
                    .padding(.bottom, 20)
                sectionDivider
                    .padding(.bottom, 20)
                supportSection
            }
            .padding(.top, 40)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
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
        HStack(spacing: 8) {
            lucideIcon(icon, size: 16)
                .foregroundStyle(accentBlue)
            Text(title)
                .font(AppTypography.headingSmall)
                .foregroundStyle(.white)
        }
    }

    // MARK: - App Info

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.top, 20)

            Spacer().frame(height: 16)

            Text("NothingHere")
                .font(AppTypography.font(size: 28, weight: .semibold))
                .foregroundStyle(.white)

            Spacer().frame(height: 4)

            Text("Version \(appVersion) (Build \(buildNumber))")
                .font(AppTypography.bodySmall)
                .foregroundStyle(dividerGray)
        }
    }

    // MARK: - Update

    private var updateSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionTitle(icon: Lucide.hardDriveUpload, title: "Software Update")

            HStack(spacing: 8) {
                Text("Automatically check for updates")
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(subtextGray)
                Toggle("", isOn: $autoCheckForUpdates)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
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
                    .font(AppTypography.bodySmall)
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
                HStack(spacing: 8) {
                    Image("KofiLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 16)
                    Text("Buy me a coffee")
                        .font(AppTypography.headingSmall)
                }
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(accentBlue, in: RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color(hex: 0x4584EE, opacity: 0.3), radius: 6, y: 4)
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
