//
//  OnboardingView.swift
//  NothingHere
//

import LucideIcons
import SwiftUI

// MARK: - Design Tokens

private enum OnboardingColors {
    static let background = Color(hex: 0x222222)
    static let accentBlue = Color(hex: 0x4584EE)
    static let warningOrange = Color(hex: 0xD54713)
    static let darkOrangeCircle = Color(hex: 0x622008)
    static let successGreen = Color(hex: 0x17D952)
    static let secondaryText = Color(hex: 0x666666)
    static let dotInactive = Color(hex: 0x444444)
    static let keyBadgeFill = Color(hex: 0x222222)
    static let dividerColor = Color(hex: 0x666666)
    static let disabledArrow = Color(hex: 0x333333)
    static let cardBorder = Color(hex: 0x444444)
}

private enum OnboardingMetrics {
    static let windowSize: CGFloat = 540
    static let stepIconSize: CGFloat = 68
    static let navButtonSize: CGFloat = 36
    static let dotSize: CGFloat = 8
    static let keyBadgeSize: CGFloat = 48
    static let keyBadgeSizeSmall: CGFloat = 32
    static let appIconSize: CGFloat = 68
    static let appIconRadius: CGFloat = 16
    static let iconCircleSize: CGFloat = 32
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

// MARK: - Navigation Direction

private enum NavigationDirection {
    case forward, backward
}

// MARK: - Helper Components

private struct StepIcon: View {
    let lucideImage: NSImage

    var body: some View {
        lucideIcon(lucideImage, size: OnboardingMetrics.stepIconSize)
            .foregroundStyle(OnboardingColors.accentBlue)
    }
}

private struct OnboardingIconCircle: View {
    let lucideImage: NSImage
    let color: Color
    var size: CGFloat = OnboardingMetrics.iconCircleSize

    var body: some View {
        lucideIcon(lucideImage, size: size * 0.5)
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color, in: Circle())
    }
}

private struct OnboardingKeyBadge: View {
    enum Content {
        case icon(NSImage)
        case text(String)
    }

    let content: Content
    var size: CGFloat = OnboardingMetrics.keyBadgeSize

    var body: some View {
        Group {
            switch content {
            case .icon(let image):
                lucideIcon(image, size: size * 0.4)
                    .foregroundStyle(.white)
            case .text(let text):
                Text(text)
                    .font(AppTypography.keycap(size: size * 0.4))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .background(OnboardingColors.keyBadgeFill, in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(OnboardingColors.cardBorder.opacity(0.3), lineWidth: 0.5)
        )
    }
}

/// Maps a modifier symbol (⌃, ⇧, ⌘, ⌥) to its corresponding Lucide icon content.
private func modifierBadgeContent(for symbol: String) -> OnboardingKeyBadge.Content {
    switch symbol {
    case "⌃": .icon(Lucide.chevronUp)
    case "⇧": .icon(Lucide.arrowBigUp)
    case "⌘": .icon(Lucide.command)
    case "⌥": .icon(Lucide.option)
    default: .text(symbol)
    }
}

// MARK: - OnboardingView

struct OnboardingView: View {
    @State var viewModel = OnboardingViewModel()
    @State private var navigationDirection: NavigationDirection = .forward

    var body: some View {
        VStack(spacing: 0) {
            // Step content
            Group {
                switch viewModel.currentStep {
                case .welcome:
                    welcomeStep
                case .permission:
                    permissionStep
                case .hotkey:
                    hotkeyStep
                case .document:
                    documentStep
                case .done:
                    doneStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(
                .asymmetric(
                    insertion: .move(edge: navigationDirection == .forward ? .trailing : .leading)
                        .combined(with: .opacity),
                    removal: .move(edge: navigationDirection == .forward ? .leading : .trailing)
                        .combined(with: .opacity)
                )
            )

            pageControls
        }
        .frame(width: OnboardingMetrics.windowSize, height: OnboardingMetrics.windowSize)
        .background(OnboardingColors.background)
        .preferredColorScheme(.dark)
        .onChange(of: viewModel.currentStep) { _, newStep in
            if newStep == .permission || newStep == .done {
                viewModel.startPermissionPolling()
            } else {
                viewModel.stopPermissionPolling()
            }
        }
        .onDisappear {
            viewModel.stopPermissionPolling()
            if viewModel.hotkeyRecorder.showRecordingPopover {
                viewModel.hotkeyRecorder.cancelRecording()
            }
        }
    }

    // MARK: - Page Controls

    private var pageControls: some View {
        HStack(spacing: 32) {
            // Back button
            Button {
                navigationDirection = .backward
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.goBack()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(AppTypography.headingSmall)
                    .foregroundStyle(viewModel.canGoBack ? .white : OnboardingColors.disabledArrow)
                    .frame(
                        width: OnboardingMetrics.navButtonSize,
                        height: OnboardingMetrics.navButtonSize
                    )
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .disabled(!viewModel.canGoBack)

            // Page dots
            HStack(spacing: 6) {
                ForEach(OnboardingViewModel.Step.allCases, id: \.rawValue) { step in
                    Circle()
                        .fill(
                            step == viewModel.currentStep
                                ? OnboardingColors.accentBlue
                                : OnboardingColors.dotInactive
                        )
                        .frame(width: OnboardingMetrics.dotSize, height: OnboardingMetrics.dotSize)
                }
            }

            // Forward / Complete button
            if viewModel.isLastStep {
                Button {
                    viewModel.complete()
                } label: {
                    Image(systemName: "checkmark")
                        .font(AppTypography.headingSmall)
                        .foregroundStyle(.white)
                        .frame(
                            width: OnboardingMetrics.navButtonSize,
                            height: OnboardingMetrics.navButtonSize
                        )
                        .background(OnboardingColors.accentBlue, in: RoundedRectangle(cornerRadius: 8))
                        .shadow(
                            color: OnboardingColors.accentBlue.opacity(0.4),
                            radius: 12,
                            y: 6
                        )
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
            } else {
                Button {
                    navigationDirection = .forward
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.goNext()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(AppTypography.headingSmall)
                        .foregroundStyle(
                            viewModel.canProceed ? .white : OnboardingColors.disabledArrow
                        )
                        .frame(
                            width: OnboardingMetrics.navButtonSize,
                            height: OnboardingMetrics.navButtonSize
                        )
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
                .disabled(!viewModel.canProceed)
            }
        }
        .padding(.bottom, 28)
        .padding(.top, 12)
    }

    // MARK: - Welcome Step

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // App logo
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    width: OnboardingMetrics.appIconSize,
                    height: OnboardingMetrics.appIconSize
                )
                .clipShape(RoundedRectangle(cornerRadius: OnboardingMetrics.appIconRadius))

            Text("Welcome to NothingHere")
                .font(AppTypography.displayMedium)
                .foregroundStyle(.white)
                .padding(.top, 16)

            Text("Your panic button for a clean screen.")
                .font(AppTypography.bodyLarge)
                .foregroundStyle(OnboardingColors.secondaryText)
                .padding(.top, 6)

            // Divider
            Rectangle()
                .fill(OnboardingColors.dividerColor)
                .frame(height: 0.5)
                .padding(.horizontal, 60)
                .padding(.top, 28)

            // Feature rows
            VStack(alignment: .leading, spacing: 14) {
                welcomeFeatureRow(icon: Lucide.appWindowMac, text: "Hides all windows instantly")
                welcomeFeatureRow(icon: Lucide.bellOff, text: "Mutes system sound")
                welcomeFeatureRow(icon: Lucide.fileCheckCorner, text: "Opens a cover document")
            }
            .padding(.top, 28)

            Spacer()
        }
        .padding(.horizontal, 48)
    }

    private func welcomeFeatureRow(icon: NSImage, text: String) -> some View {
        HStack(spacing: 12) {
            lucideIcon(icon, size: 16)
                .foregroundStyle(OnboardingColors.accentBlue)
            Text(text)
                .font(AppTypography.bodySmall)
                .foregroundStyle(.white)
        }
    }

    // MARK: - Permission Step

    private var permissionStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated icon
            StepIcon(
                lucideImage: viewModel.isAccessibilityGranted ? Lucide.folderCheck : Lucide.folderLock
            )
            .animation(.easeInOut(duration: 0.3), value: viewModel.isAccessibilityGranted)

            Text("Accessibility Permission")
                .font(AppTypography.displayMedium)
                .foregroundStyle(.white)
                .padding(.top, 16)

            Text("NothingHere needs Accessibility access to\nhide windows and listen for your hotkey.")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(OnboardingColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.top, 6)

            // Divider
            Rectangle()
                .fill(OnboardingColors.dividerColor)
                .frame(height: 0.5)
                .padding(.horizontal, 60)
                .padding(.top, 28)

            // Permission pill
            Group {
                if viewModel.isAccessibilityGranted {
                    permissionGrantedPill
                } else {
                    permissionDeniedPill
                }
            }
            .padding(.top, 28)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isAccessibilityGranted)

            Spacer()
        }
        .padding(.horizontal, 48)
    }

    private var permissionDeniedPill: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 12) {
                    OnboardingIconCircle(
                        lucideImage: Lucide.lockKeyhole,
                        color: OnboardingColors.darkOrangeCircle
                    )
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Accessibility")
                            .font(AppTypography.labelLarge)
                            .foregroundStyle(.white)
                        Text("Required to hide windows and register global hotkey")
                            .font(AppTypography.captionMedium)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                Spacer()
                Button {
                    viewModel.grantPermission()
                } label: {
                    Text("Grant Permission")
                        .font(AppTypography.buttonSmall)
                        .foregroundStyle(OnboardingColors.warningOrange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(OnboardingColors.warningOrange, in: Capsule())
        }
    }

    private var permissionGrantedPill: some View {
        HStack(spacing: 12) {
            OnboardingIconCircle(
                lucideImage: Lucide.lockKeyholeOpen,
                color: OnboardingColors.successGreen
            )
            Text("Accessibility")
                .font(AppTypography.labelLarge)
                .foregroundStyle(.white)
            Text("Granted")
                .font(AppTypography.labelSmall)
                .foregroundStyle(OnboardingColors.successGreen)
        }
        .padding(8)
        .background(OnboardingColors.successGreen.opacity(0.2), in: Capsule())
        .overlay(Capsule().strokeBorder(OnboardingColors.successGreen, lineWidth: 1))
    }

    // MARK: - Hotkey Step

    private var hotkeyStep: some View {
        VStack(spacing: 0) {
            Spacer()

            StepIcon(lucideImage: Lucide.keyboard)

            Text("Your Panic Hotkey")
                .font(AppTypography.displayMedium)
                .foregroundStyle(.white)
                .padding(.top, 16)

            Text("Press this shortcut anytime to trigger\nNothingHere.")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(OnboardingColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.top, 6)

            // Divider
            Rectangle()
                .fill(OnboardingColors.dividerColor)
                .frame(height: 0.5)
                .padding(.horizontal, 60)
                .padding(.top, 28)

            // Key badges
            if let keyName = viewModel.hotkeyRecorder.currentKeyName {
                HStack(spacing: 8) {
                    ForEach(viewModel.hotkeyRecorder.currentModifierSymbols, id: \.self) { symbol in
                        OnboardingKeyBadge(content: modifierBadgeContent(for: symbol))
                    }
                    OnboardingKeyBadge(content: .text(keyName))

                    // Reset button
                    Button {
                        viewModel.hotkeyRecorder.startRecordingHotkey()
                    } label: {
                        lucideIcon(Lucide.iterationCw, size: OnboardingMetrics.keyBadgeSize * 0.35)
                            .foregroundStyle(.white)
                            .frame(
                                width: OnboardingMetrics.keyBadgeSize,
                                height: OnboardingMetrics.keyBadgeSize
                            )
                            .background(
                                OnboardingColors.accentBlue,
                                in: RoundedRectangle(cornerRadius: 6)
                            )
                            .shadow(
                                color: OnboardingColors.accentBlue.opacity(0.3),
                                radius: 12,
                                y: 6
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Change shortcut")
                }
                .padding(.top, 28)
                .popover(isPresented: Bindable(viewModel.hotkeyRecorder).showRecordingPopover) {
                    onboardingRecordingPopover
                }
            }

            Text("Default: \u{2303}\u{2318}Z")
                .font(AppTypography.bodySmall)
                .foregroundStyle(OnboardingColors.secondaryText)
                .padding(.top, 12)

            Spacer()
        }
        .padding(.horizontal, 48)
    }

    // MARK: - Document Step

    private var documentStep: some View {
        VStack(spacing: 0) {
            Spacer()

            StepIcon(
                lucideImage: viewModel.documentManager.documentURL != nil
                    ? Lucide.fileCheckCorner : Lucide.filePlusCorner
            )

            Text("Cover Document")
                .font(AppTypography.displayMedium)
                .foregroundStyle(.white)
                .padding(.top, 16)

            Text("Optionally choose a file to open when\npanic triggers.")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(OnboardingColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.top, 6)

            // Divider
            Rectangle()
                .fill(OnboardingColors.dividerColor)
                .frame(height: 0.5)
                .padding(.horizontal, 60)
                .padding(.top, 28)

            if let url = viewModel.documentManager.documentURL {
                // File selected state
                HStack(spacing: 8) {
                    // Info bar
                    HStack(spacing: 12) {
                        lucideIcon(Lucide.image, size: 24)
                            .foregroundStyle(OnboardingColors.accentBlue)
                            .fixedSize()

                        VStack(alignment: .leading, spacing: 1) {
                            Text(url.lastPathComponent)
                                .font(AppTypography.labelMedium)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Text(url.deletingLastPathComponent().path)
                                .font(AppTypography.captionMedium)
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(OnboardingColors.keyBadgeFill, in: RoundedRectangle(cornerRadius: 6))
                    .layoutPriority(-1)

                    // Action buttons
                    Button {
                        viewModel.documentManager.pickDocument()
                    } label: {
                        Text("Change")
                            .font(AppTypography.buttonSmall)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                OnboardingColors.accentBlue,
                                in: RoundedRectangle(cornerRadius: 6)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.documentManager.removeDocument()
                    } label: {
                        lucideIcon(Lucide.fileX, size: 12)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                OnboardingColors.warningOrange,
                                in: RoundedRectangle(cornerRadius: 6)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Remove document")
                }
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(OnboardingColors.cardBorder.opacity(0.5), lineWidth: 0.5)
                )
                .padding(.top, 28)
            } else {
                // No file state
                Button {
                    viewModel.documentManager.pickDocument()
                } label: {
                    Text("Choose File")
                        .font(AppTypography.buttonLarge)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            OnboardingColors.accentBlue,
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                        .shadow(
                            color: OnboardingColors.accentBlue.opacity(0.3),
                            radius: 12,
                            y: 6
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 28)
            }

            Text("You can skip this step")
                .font(AppTypography.bodySmall)
                .foregroundStyle(OnboardingColors.secondaryText)
                .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 48)
    }

    // MARK: - Done Step

    private var doneStep: some View {
        VStack(spacing: 0) {
            Spacer()

            StepIcon(lucideImage: Lucide.laptopMinimalCheck)

            Text("You're All Set")
                .font(AppTypography.displayMedium)
                .foregroundStyle(.white)
                .padding(.top, 16)

            Text("NothingHere is ready.\nIt lives in your menu bar.")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(OnboardingColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.top, 6)

            // Summary items
            VStack(spacing: 20) {
                // Permission row (conditional)
                if viewModel.isAccessibilityGranted {
                    HStack(spacing: 12) {
                        OnboardingIconCircle(
                            lucideImage: Lucide.lockKeyholeOpen,
                            color: OnboardingColors.successGreen
                        )
                        Text("Accessibility permission")
                            .font(AppTypography.labelLarge)
                            .foregroundStyle(.white)
                        Text("Granted")
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(OnboardingColors.successGreen)
                    }
                    .padding(8)
                    .background(OnboardingColors.successGreen.opacity(0.2), in: Capsule())
                    .overlay(Capsule().strokeBorder(OnboardingColors.successGreen, lineWidth: 1))
                } else {
                    HStack {
                        HStack(spacing: 12) {
                            OnboardingIconCircle(
                                lucideImage: Lucide.lockKeyhole,
                                color: OnboardingColors.darkOrangeCircle
                            )
                            Text("Accessibility permission")
                                .font(AppTypography.labelLarge)
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Button {
                            viewModel.grantPermission()
                        } label: {
                            Text("Grant Permission")
                                .font(AppTypography.buttonSmall)
                                .foregroundStyle(OnboardingColors.warningOrange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.white, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(OnboardingColors.warningOrange, in: Capsule())
                }

                // Hotkey card
                if let keyName = viewModel.hotkeyRecorder.currentKeyName {
                    VStack(spacing: 10) {
                        // Title row
                        HStack(spacing: 6) {
                            lucideIcon(Lucide.keyboard, size: 13)
                                .foregroundStyle(OnboardingColors.accentBlue)
                            Text("Hotkey")
                                .font(AppTypography.font(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                        }

                        // Key badges
                        HStack(spacing: 12) {
                            ForEach(
                                viewModel.hotkeyRecorder.currentModifierSymbols, id: \.self
                            ) { symbol in
                                OnboardingKeyBadge(
                                    content: modifierBadgeContent(for: symbol),
                                    size: OnboardingMetrics.keyBadgeSizeSmall
                                )
                            }
                            OnboardingKeyBadge(
                                content: .text(keyName),
                                size: OnboardingMetrics.keyBadgeSizeSmall
                            )
                        }
                    }
                }
            }
            .padding(.top, 20)

            // Open Settings button
            Button {
                viewModel.requestsSettingsOpen = true
                viewModel.complete()
            } label: {
                Text("Open Settings")
                    .font(AppTypography.buttonLarge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        OnboardingColors.accentBlue,
                        in: RoundedRectangle(cornerRadius: 6)
                    )
                    .shadow(
                        color: OnboardingColors.accentBlue.opacity(0.3),
                        radius: 12,
                        y: 6
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 20)

            Spacer()
        }
        .padding(.horizontal, 48)
    }

    // MARK: - Recording Popover

    private var onboardingRecordingPopover: some View {
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
}

#Preview {
    OnboardingView()
}
