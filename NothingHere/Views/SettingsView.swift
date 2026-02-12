//
//  SettingsView.swift
//  NothingHere
//

import AppKit
import Sparkle
import SwiftUI

struct SettingsView: View {
    let updater: SPUUpdater

    enum SettingsTab: String, CaseIterable {
        case general, help, about

        var title: String {
            switch self {
            case .general: "General"
            case .help: "Help"
            case .about: "About"
            }
        }

        var icon: String {
            switch self {
            case .general: "gearshape"
            case .help: "book"
            case .about: "info.circle"
            }
        }
    }

    @State private var selectedTab: SettingsTab = .general
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 560)
        .frame(minHeight: 520)
        .onAppear {
            viewModel.onAppear()
            NSApp.activate()
            if let window = NSApp.windows.first(where: { $0.isVisible && $0.level == .normal }) {
                window.orderFrontRegardless()
            }
        }
        .onDisappear { viewModel.onDisappear() }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 2) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Label(tab.title, systemImage: tab.icon)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(
                            selectedTab == tab
                                ? AnyShapeStyle(.selection)
                                : AnyShapeStyle(.clear),
                            in: .rect(cornerRadius: 6)
                        )
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
            }
            Spacer()
        }
        .padding(8)
        .frame(width: 160)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .general:
            GeneralTab(viewModel: viewModel)
        case .help:
            InstructionsTab()
        case .about:
            AboutTab(updater: updater)
        }
    }
}

// MARK: - GeneralTab

private struct GeneralTab: View {
    @Bindable var viewModel: SettingsViewModel

    private var guardMode: GuardModeManager { GuardModeManager.shared }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                permissionCard
                hotkeyCard
                guardModeCard
                documentCard
            }
            .padding(20)
        }
    }

    // MARK: - Permission Card

    private var permissionCard: some View {
        SettingsCard(header: "Permissions") {
            if viewModel.isAccessibilityGranted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                    Text("Accessibility")
                        .font(.body)
                    Spacer()
                    Text("Granted")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Accessibility")
                                .font(.body)
                            Text("Required to hide windows and register global hotkey")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button("Grant Permission") {
                        viewModel.grantPermission()
                    }
                    .controlSize(.small)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("If the dialog doesn't appear:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(
                            "System Settings \u{2192} Privacy & Security \u{2192} Accessibility \u{2192} Enable \"NothingHere\""
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Button("Open System Settings") {
                        viewModel.openPermissionSettings()
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.orange.opacity(0.08), in: .rect(cornerRadius: 8))
            }
        }
    }

    // MARK: - Hotkey Card

    private var hotkeyCard: some View {
        SettingsCard(header: "Panic Hotkey") {
            VStack(alignment: .leading, spacing: 12) {
                hotkeyDisplay
                    .popover(isPresented: $viewModel.showRecordingPopover) {
                        hotkeyRecordingPopover
                    }

                if let conflict = viewModel.hotkeyConflictMessage {
                    Label(conflict, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var hotkeyDisplay: some View {
        Button {
            viewModel.startRecordingHotkey()
        } label: {
            if let keyName = viewModel.currentKeyName {
                HStack(spacing: 4) {
                    ForEach(viewModel.currentModifierSymbols, id: \.self) { symbol in
                        KeyBadge(text: symbol)
                    }
                    KeyBadge(text: keyName)
                }
            } else {
                Text("Record Shortcut")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .strokeBorder(
                                .secondary.opacity(0.4),
                                style: StrokeStyle(lineWidth: 1, dash: [5, 3])
                            )
                    }
            }
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
    }

    // MARK: - Hotkey Recording Popover

    private var hotkeyRecordingPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            HotkeyRecorderView(
                onKeyDown: { event in viewModel.handleKeyEvent(event) },
                onFlagsChanged: { event in viewModel.handleFlagsChanged(event) }
            )
            .frame(height: 0)

            HStack {
                if !viewModel.liveModifierSymbols.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(
                            Array(viewModel.liveModifierSymbols.enumerated()),
                            id: \.offset
                        ) { _, symbol in
                            KeyBadge(text: symbol)
                        }
                    }
                }
                Spacer()
                Button {
                    viewModel.cancelRecording()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
            }

            if viewModel.isPendingReady {
                EmptyView()
            } else if let conflict = viewModel.pendingConflict {
                Text(conflict)
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Text("Recording...")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if viewModel.isPendingReady {
                HStack {
                    Button("Reset") {
                        viewModel.resetRecording()
                    }
                    .controlSize(.small)
                    .foregroundStyle(.red)
                    Spacer()
                    Button("Confirm") {
                        viewModel.confirmHotkey()
                    }
                    .controlSize(.small)
                }
            }
        }
        .padding(12)
        .frame(width: 240)
    }

    // MARK: - Guard Mode Card

    private var guardModeCard: some View {
        SettingsCard(header: "Guard Mode") {
            VStack(alignment: .leading, spacing: 12) {
                Text(
                    "When armed, the very next key press will trigger the panic sequence and automatically disarm. Any key works \u{2014} no modifier needed. You can also arm from the menu bar."
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(guardMode.isArmed ? .red : Color(.separatorColor))
                            .frame(width: 8, height: 8)
                        Text(guardMode.isArmed ? "Armed" : "Disarmed")
                            .font(.body)
                            .foregroundStyle(guardMode.isArmed ? .primary : .secondary)
                    }
                    Spacer()
                    Button(guardMode.isArmed ? "Disarm" : "Arm") {
                        guardMode.toggle()
                    }
                    .controlSize(.small)
                }
            }
        }
    }

    // MARK: - Document Card

    private var documentCard: some View {
        SettingsCard(header: "Cover Document") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Open a file when panic is triggered", isOn: $viewModel.openDocumentEnabled)
                    .toggleStyle(.switch)

                if viewModel.openDocumentEnabled {
                    if let url = viewModel.documentURL {
                        HStack(spacing: 10) {
                            fileIcon(for: url)
                                .resizable()
                                .frame(width: 32, height: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(url.lastPathComponent)
                                    .font(.body)
                                Text(url.deletingLastPathComponent().path)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            Spacer()
                            Button("Change") {
                                viewModel.pickDocument()
                            }
                            .controlSize(.small)
                        }
                    }

                    if !viewModel.isDocumentValid {
                        Label(
                            "Selected file is no longer available. Please choose a new file.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    private func fileIcon(for url: URL) -> Image {
        let nsImage = NSWorkspace.shared.icon(forFile: url.path)
        return Image(nsImage: nsImage)
    }
}

// MARK: - KeyBadge

private struct KeyBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.quaternary, in: .rect(cornerRadius: 6))
    }
}

// MARK: - SettingsCard

struct SettingsCard<Content: View>: View {
    let header: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header)
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: .rect(cornerRadius: 10))
        }
    }
}

#Preview {
    SettingsView(updater: SPUStandardUpdaterController(
        startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil
    ).updater)
}
