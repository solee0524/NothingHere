//
//  MenuBarPopoverView.swift
//  NothingHere
//

import LucideIcons
import Sparkle
import SwiftUI

// MARK: - Design Tokens

private enum PopoverColors {
    static let background = Color(hex: 0x111111, opacity: 0.9)
    static let accentBlue = Color(hex: 0x4584EE)
    static let divider = Color(hex: 0x666666)
    static let keyBadgeFill = Color(hex: 0x333333)
    static let keyBadgeBorder = Color(hex: 0x444444)
    static let secondaryText = Color(hex: 0x666666)
    static let toggleOff = Color(hex: 0x333333)
}

private enum PopoverMetrics {
    static let cornerRadius: CGFloat = 16
    static let padding: CGFloat = 16
    static let dividerSpacing: CGFloat = 8
    static let iconSize: CGFloat = 16
    static let keyBadgeSize: CGFloat = 36
    static let keyBadgeCornerRadius: CGFloat = 8
    static let toggleWidth: CGFloat = 44
    static let toggleHeight: CGFloat = 26
    static let appIconSize: CGFloat = 24
    static let headerFontSize: CGFloat = 16
    static let menuItemFontSize: CGFloat = 14
    static let menuItemIconSize: CGFloat = 16
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

// MARK: - PopoverKeyBadge

private struct PopoverKeyBadge: View {
    enum Content {
        case icon(NSImage)
        case text(String)
    }

    let content: Content

    var body: some View {
        Group {
            switch content {
            case .icon(let image):
                lucideIcon(image, size: PopoverMetrics.keyBadgeSize * 0.4)
                    .foregroundStyle(.white)
            case .text(let text):
                Text(text)
                    .font(AppTypography.keycap(
                        size: PopoverMetrics.keyBadgeSize * 0.4
                    ))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: PopoverMetrics.keyBadgeSize, height: PopoverMetrics.keyBadgeSize)
        .background(
            PopoverColors.keyBadgeFill,
            in: RoundedRectangle(cornerRadius: PopoverMetrics.keyBadgeCornerRadius)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PopoverMetrics.keyBadgeCornerRadius)
                .strokeBorder(PopoverColors.keyBadgeBorder.opacity(0.5), lineWidth: 0.5)
        )
    }
}

// MARK: - PopoverToggle

private struct PopoverToggle: View {
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? PopoverColors.accentBlue : PopoverColors.toggleOff)
                Circle()
                    .fill(.white)
                    .padding(3)
            }
            .frame(width: PopoverMetrics.toggleWidth, height: PopoverMetrics.toggleHeight)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .animation(.easeInOut(duration: 0.2), value: isOn)
    }
}

// MARK: - PopoverDivider

private struct PopoverDivider: View {
    var body: some View {
        Rectangle()
            .fill(PopoverColors.divider)
            .frame(height: 1)
            .padding(.vertical, PopoverMetrics.dividerSpacing)
    }
}

// MARK: - PopoverMenuItem

private struct PopoverMenuItem: View {
    let icon: NSImage
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                lucideIcon(icon, size: PopoverMetrics.menuItemIconSize)
                    .foregroundStyle(PopoverColors.accentBlue)
                Text(title)
                    .font(AppTypography.font(
                        size: PopoverMetrics.menuItemFontSize
                    ))
                    .foregroundStyle(.white)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PopoverWindowAccessor

private struct PopoverWindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - Modifier Badge Mapping

/// Maps a modifier symbol (⌃, ⇧, ⌘, ⌥) to its corresponding badge content.
private func modifierBadgeContent(for symbol: String) -> PopoverKeyBadge.Content {
    switch symbol {
    case "⌃": .icon(Lucide.chevronUp)
    case "⇧": .icon(Lucide.arrowBigUp)
    case "⌘": .icon(Lucide.command)
    case "⌥": .icon(Lucide.option)
    default: .text(symbol)
    }
}

// MARK: - MenuBarPopoverView

struct MenuBarPopoverView: View {
    let appDelegate: AppDelegate
    @Environment(\.openSettings) private var openSettings
    @Environment(\.dismiss) private var dismiss

    private var guardMode: GuardModeManager { GuardModeManager.shared }

    private var hotkeyKeyCode: UInt16 {
        UInt16(UserDefaults.standard.integer(forKey: "hotkeyKeyCode"))
    }

    private var hotkeyModifiers: UInt32 {
        UInt32(UserDefaults.standard.integer(forKey: "hotkeyModifiers"))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            logoHeader
            PopoverDivider()
            panicHotkeySection
            PopoverDivider()
            guardModeSection
            PopoverDivider()
            menuItems
            PopoverDivider()
            quitItem
        }
        .padding(PopoverMetrics.padding)
        .fixedSize()
        .background(PopoverColors.background)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: PopoverMetrics.cornerRadius))
        .background {
            PopoverWindowAccessor()
        }
        .onAppear {
            appDelegate.openSettingsAction = { [openSettings] in
                openSettings()
            }
        }
    }

    // MARK: - Logo Header

    private var logoHeader: some View {
        HStack(spacing: 8) {
            if let appIcon = NSApp.applicationIconImage {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(
                        width: PopoverMetrics.appIconSize,
                        height: PopoverMetrics.appIconSize
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            Text("We are here !")
                .font(AppTypography.font(
                    size: PopoverMetrics.headerFontSize
                ))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Panic Hotkey Section

    private var panicHotkeySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                lucideIcon(Lucide.keyboard, size: 14)
                    .foregroundStyle(PopoverColors.accentBlue)
                Text("Panic Hotkey")
                    .font(AppTypography.font(
                        size: PopoverMetrics.menuItemFontSize
                    ))
                    .foregroundStyle(.white)
            }

            if hotkeyKeyCode != 0 || hotkeyModifiers != 0 {
                HStack(spacing: 6) {
                    let symbols = KeyCodeMapper.modifierSymbolList(for: hotkeyModifiers)
                    ForEach(symbols, id: \.self) { symbol in
                        PopoverKeyBadge(content: modifierBadgeContent(for: symbol))
                    }
                    PopoverKeyBadge(content: .text(KeyCodeMapper.keyName(for: hotkeyKeyCode)))
                }
            } else {
                Text("Not configured")
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(PopoverColors.secondaryText)
            }
        }
    }

    // MARK: - Guard Mode Section

    private var guardModeSection: some View {
        HStack(spacing: 12) {
            lucideIcon(Lucide.shield, size: 14)
                .foregroundStyle(PopoverColors.accentBlue)
            Text("Arm Guard Mode")
                .font(AppTypography.font(
                    size: PopoverMetrics.menuItemFontSize
                ))
                .foregroundStyle(.white)
            PopoverToggle(isOn: guardMode.isArmed) {
                guardMode.toggle()
            }
        }
    }

    // MARK: - Menu Items

    private var menuItems: some View {
        VStack(spacing: 8) {
            PopoverMenuItem(icon: Lucide.settings2, title: "Settings\u{2026}") {
                dismiss()
                DispatchQueue.main.async {
                    appDelegate.openSettingsWindow()
                }
            }
            PopoverMenuItem(icon: Lucide.album, title: "Setup Guide\u{2026}") {
                dismiss()
                DispatchQueue.main.async {
                    appDelegate.showOnboardingWindow()
                }
            }
            PopoverMenuItem(icon: Lucide.monitorUp, title: "Check for Updates\u{2026}") {
                dismiss()
                DispatchQueue.main.async {
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate()
                    appDelegate.updaterController.checkForUpdates(nil)
                }
            }
        }
    }

    // MARK: - Quit

    private var quitItem: some View {
        PopoverMenuItem(icon: Lucide.logOut, title: "Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
