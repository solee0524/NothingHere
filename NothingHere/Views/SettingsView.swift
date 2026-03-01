//
//  SettingsView.swift
//  NothingHere
//

import AppKit
import LucideIcons
import Sparkle
import SwiftUI

// MARK: - Design Tokens

private enum DesignColors {
    static let background = Color(hex: 0x222222)
    static let sidebarTop = Color(hex: 0x111111)
    static let sidebarBottom = Color(hex: 0x222222)
    static let cardFill = Color(hex: 0x0D0D0D)
    static let cardBorder = Color(hex: 0x444444)
    static let accentBlue = Color(hex: 0x4584EE)
    static let warningOrange = Color(hex: 0xD54713)
    static let successGreen = Color(hex: 0x17D952)
    static let secondaryText = Color(hex: 0x666666)
    static let tabUnselected = Color(hex: 0x666666).opacity(0.2)
    static let keyBadgeFill = Color(hex: 0x222222)
    static let darkOrangeCircle = Color(hex: 0x622008)
}

private enum DesignMetrics {
    static let windowWidth: CGFloat = 740
    static let windowMinHeight: CGFloat = 560
    static let sidebarWidth: CGFloat = 180
    static let cardCornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let pillCornerRadius: CGFloat = 35
    static let iconCircleSize: CGFloat = 32
    static let keyBadgeSize: CGFloat = 48
    static let tabCornerRadius: CGFloat = 16
}

// MARK: - Color Extension

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

// MARK: - Lucide Helper

private func lucideIcon(_ image: NSImage, size: CGFloat = 14) -> some View {
    Image(nsImage: image)
        .renderingMode(.template)
        .resizable()
        .frame(width: size, height: size)
}

// MARK: - Helper Components

private struct IconCircle: View {
    let lucideImage: NSImage
    let color: Color
    var size: CGFloat = DesignMetrics.iconCircleSize

    var body: some View {
        lucideIcon(lucideImage, size: size * 0.5)
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color, in: Circle())
    }
}

private struct StatusPill<Leading: View, Trailing: View>: View {
    let color: Color
    var isSolid: Bool = false
    @ViewBuilder let leading: Leading
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack {
            leading
            Spacer()
            trailing
        }
        .padding(8)
        .background(isSolid ? color : color.opacity(0.2), in: Capsule())
        .overlay {
            if !isSolid {
                Capsule().strokeBorder(color, lineWidth: 1)
            }
        }
    }
}

private struct BreadcrumbStep: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppTypography.captionMedium)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(DesignColors.keyBadgeFill, in: RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(DesignColors.cardBorder.opacity(0.3), lineWidth: 0.5)
            )
    }
}

private struct SidebarTabButton: View {
    let title: String
    let lucideImage: NSImage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                lucideIcon(lucideImage, size: 18)
                    .foregroundStyle(isSelected ? DesignColors.accentBlue : DesignColors.secondaryText)
                Text(title)
                    .font(AppTypography.headingSmall)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 60)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: DesignMetrics.tabCornerRadius)
                    .fill(isSelected ? .black : DesignColors.tabUnselected)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignMetrics.tabCornerRadius)
                    .strokeBorder(
                        isSelected ? DesignColors.accentBlue : .clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            )
            .shadow(
                color: isSelected ? .black.opacity(0.5) : .clear,
                radius: isSelected ? 16 : 0,
                y: isSelected ? 12 : 0
            )
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
    }
}

// MARK: - SettingsView

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

        var lucideImage: NSImage {
            switch self {
            case .general: Lucide.copy
            case .help: Lucide.album
            case .about: Lucide.mousePointerClick
            }
        }
    }

    @State private var selectedTab: SettingsTab = .general
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .background(DesignColors.background)
        .background {
            WindowAccessor { window in
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.title = ""
                window.styleMask.insert(.fullSizeContentView)
                window.titlebarSeparatorStyle = .none
                window.isMovableByWindowBackground = true
                window.backgroundColor = .clear
            }
        }
        .toolbarBackground(.hidden, for: .windowToolbar)
        .frame(width: DesignMetrics.windowWidth)
        .frame(minHeight: DesignMetrics.windowMinHeight)
        .preferredColorScheme(.dark)
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
        VStack(spacing: 16) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                SidebarTabButton(
                    title: tab.title,
                    lucideImage: tab.lucideImage,
                    isSelected: selectedTab == tab
                ) {
                    selectedTab = tab
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .frame(width: DesignMetrics.sidebarWidth)
        .background(
            LinearGradient(
                stops: [
                    .init(color: DesignColors.sidebarTop, location: 0),
                    .init(color: DesignColors.sidebarBottom, location: 0.5),
                    .init(color: DesignColors.sidebarBottom, location: 1.0),
                ],
                startPoint: .trailing,
                endPoint: .leading
            )
        )
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        VStack(spacing: 0) {
            contentHeader
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

    private var contentHeader: some View {
        HStack {
            Text("NothingHere")
                .font(AppTypography.headingMedium)
                .foregroundStyle(.white)
            Spacer()
            lucideIcon(Lucide.mousePointerClick, size: 14)
                .foregroundStyle(.white)
                .padding(6)
                .background(DesignColors.accentBlue, in: Circle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 8)
    }
}

// MARK: - GeneralTab

private struct GeneralTab: View {
    @Bindable var viewModel: SettingsViewModel

    private var guardMode: GuardModeManager { GuardModeManager.shared }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                permissionCard
                hotkeyCard
                guardModeCard
                documentCard
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Permission Card

    private var permissionCard: some View {
        SettingsCard(header: "Permissions", lucideIcon: Lucide.screenShare) {
            if viewModel.isAccessibilityGranted {
                permissionGrantedContent
            } else {
                permissionDeniedContent
            }
        }
    }

    private var permissionGrantedContent: some View {
        StatusPill(color: DesignColors.successGreen) {
            HStack(spacing: 12) {
                IconCircle(lucideImage: Lucide.lockKeyholeOpen, color: DesignColors.successGreen)
                Text("Accessibility")
                    .font(AppTypography.labelLarge)
                    .foregroundStyle(.white)
            }
        } trailing: {
            Text("Granted")
                .font(AppTypography.labelSmall)
                .foregroundStyle(DesignColors.successGreen)
                .padding(.trailing, 4)
        }
    }

    private var permissionDeniedContent: some View {
        VStack(spacing: 12) {
            StatusPill(color: DesignColors.warningOrange, isSolid: true) {
                HStack(spacing: 12) {
                    IconCircle(lucideImage: Lucide.lockKeyhole, color: DesignColors.darkOrangeCircle)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Accessibility")
                            .font(AppTypography.labelLarge)
                            .foregroundStyle(.white)
                        Text("Required to hide windows and register global hotkey")
                            .font(AppTypography.captionMedium)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            } trailing: {
                Button {
                    viewModel.grantPermission()
                } label: {
                    Text("Grant Permission")
                        .font(AppTypography.buttonSmall)
                        .foregroundStyle(DesignColors.warningOrange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Text("If the dialog doesn't appear, please follow the troubleshooting steps below")
                .font(AppTypography.captionMedium)
                .foregroundStyle(DesignColors.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            HStack(spacing: 6) {
                BreadcrumbStep(text: "System Settings")
                Image(systemName: "chevron.right")
                    .font(AppTypography.captionTiny)
                    .foregroundStyle(.white.opacity(0.5))
                BreadcrumbStep(text: "Privacy & Security")
                Image(systemName: "chevron.right")
                    .font(AppTypography.captionTiny)
                    .foregroundStyle(.white.opacity(0.5))
                BreadcrumbStep(text: "Accessibility")
                Image(systemName: "chevron.right")
                    .font(AppTypography.captionTiny)
                    .foregroundStyle(.white.opacity(0.5))
                BreadcrumbStep(text: "NothingHere")
            }

            Button {
                viewModel.openPermissionSettings()
            } label: {
                Text("Open System Settings")
                    .font(AppTypography.font(size: 10, weight: .medium))
                    .foregroundStyle(DesignColors.accentBlue)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Hotkey Card

    private var hotkeyCard: some View {
        SettingsCard(header: "Panic Hotkey", lucideIcon: Lucide.grip) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    hotkeyDisplay
                        .popover(isPresented: Bindable(viewModel.hotkeyRecorder).showRecordingPopover) {
                            hotkeyRecordingPopover
                        }
                }

                if let conflict = viewModel.hotkeyRecorder.hotkeyConflictMessage {
                    Label(conflict, systemImage: "exclamationmark.triangle.fill")
                        .font(AppTypography.captionLarge)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var hotkeyDisplay: some View {
        Button {
            viewModel.hotkeyRecorder.startRecordingHotkey()
        } label: {
            if let keyName = viewModel.hotkeyRecorder.currentKeyName {
                HStack(spacing: 8) {
                    ForEach(viewModel.hotkeyRecorder.currentModifierSymbols, id: \.self) { symbol in
                        KeyBadge(text: symbol, style: .large)
                    }
                    KeyBadge(text: keyName, style: .large)

                    Button {
                        viewModel.hotkeyRecorder.startRecordingHotkey()
                    } label: {
                        lucideIcon(Lucide.iterationCw, size: 14)
                            .foregroundStyle(.white)
                            .frame(
                                width: DesignMetrics.keyBadgeSize,
                                height: DesignMetrics.keyBadgeSize
                            )
                            .background(
                                DesignColors.accentBlue,
                                in: RoundedRectangle(cornerRadius: 6)
                            )
                            .shadow(
                                color: DesignColors.accentBlue.opacity(0.3),
                                radius: 12,
                                y: 6
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Change shortcut")
                }
            } else {
                Text("Record Shortcut")
                    .font(AppTypography.buttonMedium)
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
                onKeyDown: { event in viewModel.hotkeyRecorder.handleKeyEvent(event) },
                onFlagsChanged: { event in viewModel.hotkeyRecorder.handleFlagsChanged(event) }
            )
            .frame(height: 0)

            HStack {
                if !viewModel.hotkeyRecorder.liveModifierSymbols.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(
                            Array(viewModel.hotkeyRecorder.liveModifierSymbols.enumerated()),
                            id: \.offset
                        ) { _, symbol in
                            KeyBadge(text: symbol)
                        }
                    }
                }
                Spacer()
                Button {
                    viewModel.hotkeyRecorder.cancelRecording()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(AppTypography.headingMedium)
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
            }

            if viewModel.hotkeyRecorder.isPendingReady {
                EmptyView()
            } else if let conflict = viewModel.hotkeyRecorder.pendingConflict {
                Text(conflict)
                    .font(AppTypography.captionLarge)
                    .foregroundStyle(.orange)
            } else {
                Text("Recording...")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(.secondary)
            }

            if viewModel.hotkeyRecorder.isPendingReady {
                HStack {
                    Button("Reset") {
                        viewModel.hotkeyRecorder.resetRecording()
                    }
                    .controlSize(.small)
                    .foregroundStyle(.red)
                    Spacer()
                    Button("Confirm") {
                        viewModel.hotkeyRecorder.confirmHotkey()
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
        SettingsCard(header: "Guard Mode", lucideIcon: Lucide.shield) {
            VStack(spacing: 12) {
                Text(
                    "When armed, the very next key press will trigger the panic sequence and automatically disarm. Any key works \u{2014} no modifier needed. You can also arm from the menu bar."
                )
                .font(AppTypography.captionLarge)
                .foregroundStyle(DesignColors.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

                if guardMode.isArmed {
                    StatusPill(color: DesignColors.successGreen) {
                        HStack(spacing: 12) {
                            IconCircle(lucideImage: Lucide.shieldCheck, color: DesignColors.successGreen)
                            Text("Armed")
                                .font(AppTypography.labelLarge)
                                .foregroundStyle(.white)
                        }
                    } trailing: {
                        Button {
                            guardMode.toggle()
                        } label: {
                            Text("Disarm")
                                .font(AppTypography.buttonSmall)
                                .foregroundStyle(DesignColors.cardFill)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.white, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    StatusPill(color: DesignColors.secondaryText) {
                        HStack(spacing: 12) {
                            IconCircle(
                                lucideImage: Lucide.shield,
                                color: DesignColors.secondaryText.opacity(0.5)
                            )
                            Text("Disarmed")
                                .font(AppTypography.labelLarge)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    } trailing: {
                        Button {
                            guardMode.toggle()
                        } label: {
                            Text("Arm")
                                .font(AppTypography.buttonSmall)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    DesignColors.secondaryText.opacity(0.5),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Document Card

    private var documentCard: some View {
        let isEnabled = viewModel.documentManager.openDocumentEnabled
        let pillColor = isEnabled ? DesignColors.accentBlue : DesignColors.secondaryText

        return SettingsCard(header: "Cover Document", lucideIcon: Lucide.filePlus) {
            VStack(alignment: .leading, spacing: 12) {
                StatusPill(color: pillColor) {
                    HStack(spacing: 12) {
                        IconCircle(lucideImage: Lucide.fileCheck, color: pillColor)
                        Text("Open a file when panic is triggered")
                            .font(AppTypography.font(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                } trailing: {
                    Toggle(
                        "",
                        isOn: Bindable(viewModel.documentManager).openDocumentEnabled
                    )
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.small)
                    .tint(DesignColors.accentBlue)
                }

                if let url = viewModel.documentManager.documentURL {
                    HStack(spacing: 12) {
                        fileIcon(for: url)
                            .resizable()
                            .frame(width: 28, height: 28)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(url.lastPathComponent)
                                .font(AppTypography.labelMedium)
                                .foregroundStyle(.white)
                            Text(url.deletingLastPathComponent().path)
                                .font(AppTypography.captionMedium)
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()

                        Button {
                            viewModel.documentManager.pickDocument()
                        } label: {
                            Text("Change")
                                .font(AppTypography.buttonSmall)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(DesignColors.accentBlue, in: RoundedRectangle(cornerRadius: 6))
                                .shadow(
                                    color: DesignColors.accentBlue.opacity(0.3),
                                    radius: 12,
                                    y: 6
                                )
                        }
                        .buttonStyle(.plain)

                        Button {
                            viewModel.documentManager.removeDocument()
                        } label: {
                            lucideIcon(Lucide.fileX, size: 12)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(DesignColors.warningOrange, in: RoundedRectangle(cornerRadius: 6))
                                .shadow(
                                    color: DesignColors.warningOrange.opacity(0.3),
                                    radius: 12,
                                    y: 6
                                )
                        }
                        .buttonStyle(.plain)
                        .help("Remove document")
                    }
                    .padding(12)
                    .background(DesignColors.keyBadgeFill, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(DesignColors.cardBorder.opacity(0.3), lineWidth: 0.5)
                    )
                    .opacity(viewModel.documentManager.openDocumentEnabled ? 1 : 0.5)
                } else {
                    HStack(spacing: 12) {
                        lucideIcon(Lucide.folderPlus, size: 28)
                            .foregroundStyle(DesignColors.accentBlue)
                        Text("Add File")
                            .font(AppTypography.labelMedium)
                            .foregroundStyle(.white)
                        Spacer()
                        Button {
                            viewModel.documentManager.pickDocument()
                        } label: {
                            Text("Choose File")
                                .font(AppTypography.buttonSmall)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(DesignColors.accentBlue, in: RoundedRectangle(cornerRadius: 6))
                                .shadow(
                                    color: DesignColors.accentBlue.opacity(0.3),
                                    radius: 12,
                                    y: 6
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(DesignColors.keyBadgeFill, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(DesignColors.cardBorder.opacity(0.3), lineWidth: 0.5)
                    )
                }

                if !viewModel.documentManager.isDocumentValid {
                    Label(
                        "Selected file is no longer available. Please choose a new file.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(AppTypography.captionLarge)
                    .foregroundStyle(.orange)
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

struct KeyBadge: View {
    enum Style {
        case compact, large
    }

    let text: String
    var style: Style = .compact

    var body: some View {
        switch style {
        case .compact:
            Text(text)
                .font(AppTypography.keycap(size: 16, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.quaternary, in: .rect(cornerRadius: 6))
        case .large:
            Text(text)
                .font(AppTypography.keycap(size: 18))
                .foregroundStyle(.white)
                .frame(width: DesignMetrics.keyBadgeSize, height: DesignMetrics.keyBadgeSize)
                .background(DesignColors.keyBadgeFill, in: RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(DesignColors.cardBorder.opacity(0.3), lineWidth: 0.5)
                )
        }
    }
}

// MARK: - SettingsCard

struct SettingsCard<Content: View>: View {
    let header: String
    var lucideIcon: NSImage?
    @ViewBuilder let content: Content

    init(header: String, lucideIcon: NSImage? = nil, @ViewBuilder content: () -> Content) {
        self.header = header
        self.lucideIcon = lucideIcon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                if let lucideIcon {
                    Image(nsImage: lucideIcon)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(DesignColors.accentBlue)
                }
                Text(header)
                    .font(AppTypography.headingSmall)
                    .foregroundStyle(.white)
            }

            content
        }
        .padding(DesignMetrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignColors.cardFill, in: RoundedRectangle(cornerRadius: DesignMetrics.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DesignMetrics.cardCornerRadius)
                .strokeBorder(DesignColors.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - WindowAccessor

private struct WindowAccessor: NSViewRepresentable {
    var configure: (NSWindow) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            configure(window)
            context.coordinator.observe(window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            configure(window)
        }
    }

    final class Coordinator: NSObject {
        private var observation: NSKeyValueObservation?

        func observe(_ window: NSWindow) {
            observation = window.observe(\.title, options: .new) { win, _ in
                if !win.title.isEmpty {
                    win.title = ""
                    win.titleVisibility = .hidden
                }
            }
        }

        deinit {
            observation?.invalidate()
        }
    }
}

#Preview {
    SettingsView(updater: SPUStandardUpdaterController(
        startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil
    ).updater)
}
