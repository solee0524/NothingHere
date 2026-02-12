//
//  OnboardingView.swift
//  NothingHere
//

import SwiftUI

struct OnboardingView: View {
    @State var viewModel = OnboardingViewModel()

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
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
            )

            Divider()

            // Bottom bar: page indicator + navigation
            HStack {
                // Back button
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.goBack()
                    }
                }
                .opacity(viewModel.canGoBack ? 1 : 0)
                .disabled(!viewModel.canGoBack)

                Spacer()

                // Page indicator dots
                HStack(spacing: 6) {
                    ForEach(OnboardingViewModel.Step.allCases, id: \.rawValue) { step in
                        Circle()
                            .fill(step == viewModel.currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 7, height: 7)
                    }
                }

                Spacer()

                // Continue / Get Started button
                if viewModel.isLastStep {
                    Button("Get Started") {
                        viewModel.complete()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                } else {
                    Button("Continue") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.goNext()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(!viewModel.canProceed)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 500, height: 460)
        .onChange(of: viewModel.currentStep) { _, newStep in
            if newStep == .permission {
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

    // MARK: - Welcome Step

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "eye.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Welcome to NothingHere")
                .font(.title2.bold())

            Text("Your panic button for a clean screen")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "macwindow", text: "Hides all windows instantly")
                featureRow(icon: "speaker.slash", text: "Mutes system sound")
                featureRow(icon: "doc", text: "Opens a cover document")
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Permission Step

    private var permissionStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(viewModel.isAccessibilityGranted ? .green : .orange)

            Text("Accessibility Permission")
                .font(.title2.bold())

            Text("NothingHere needs Accessibility access to hide windows and listen for your hotkey.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Status indicator
            HStack(spacing: 8) {
                Image(systemName: viewModel.isAccessibilityGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(viewModel.isAccessibilityGranted ? .green : .orange)
                    .font(.title3)
                Text(viewModel.isAccessibilityGranted ? "Permission granted" : "Permission required")
                    .font(.callout)
                    .foregroundStyle(viewModel.isAccessibilityGranted ? .secondary : .primary)
            }
            .padding(.vertical, 4)

            if !viewModel.isAccessibilityGranted {
                Button("Grant Permission") {
                    viewModel.grantPermission()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Open System Settings") {
                    viewModel.openPermissionSettings()
                }
                .buttonStyle(.link)
                .font(.caption)

                Text("System Settings \u{2192} Privacy & Security \u{2192} Accessibility")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Hotkey Step

    private var hotkeyStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "keyboard.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Your Panic Hotkey")
                .font(.title2.bold())

            Text("Press this shortcut anytime to trigger NothingHere.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Current hotkey display
            if let keyName = viewModel.hotkeyRecorder.currentKeyName {
                HStack(spacing: 4) {
                    ForEach(viewModel.hotkeyRecorder.currentModifierSymbols, id: \.self) { symbol in
                        KeyBadge(text: symbol)
                    }
                    KeyBadge(text: keyName)
                }
                .popover(isPresented: Bindable(viewModel.hotkeyRecorder).showRecordingPopover) {
                    onboardingRecordingPopover
                }
            }

            Button("Change") {
                viewModel.hotkeyRecorder.startRecordingHotkey()
            }
            .controlSize(.small)

            Text("Default: \u{2303}\u{2318}Z")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Document Step

    private var documentStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "doc.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Cover Document")
                .font(.title2.bold())

            Text("Optionally choose a file to open when panic triggers.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let url = viewModel.documentManager.documentURL {
                HStack(spacing: 8) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text(url.lastPathComponent)
                        .font(.callout)
                        .lineLimit(1)
                }
                .padding(10)
                .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 8))

                HStack(spacing: 12) {
                    Button("Change\u{2026}") {
                        viewModel.documentManager.pickDocument()
                    }
                    .controlSize(.small)

                    Button("Remove") {
                        viewModel.documentManager.removeDocument()
                    }
                    .controlSize(.small)
                    .foregroundStyle(.red)
                }
            } else {
                Button("Choose File\u{2026}") {
                    viewModel.documentManager.pickDocument()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Text("You can skip this step")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Done Step

    private var doneStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("You're All Set")
                .font(.title2.bold())

            Text("NothingHere is ready. It lives in your menu bar.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Summary
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Accessibility permission")
                        .font(.callout)
                }

                HStack(spacing: 8) {
                    Image(systemName: "keyboard")
                        .foregroundStyle(.tint)
                    if let keyName = viewModel.hotkeyRecorder.currentKeyName {
                        HStack(spacing: 3) {
                            Text("Hotkey:")
                                .font(.callout)
                            ForEach(viewModel.hotkeyRecorder.currentModifierSymbols, id: \.self) { symbol in
                                KeyBadge(text: symbol)
                            }
                            KeyBadge(text: keyName)
                        }
                    }
                }

                if let url = viewModel.documentManager.documentURL {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(.tint)
                        Text(url.lastPathComponent)
                            .font(.callout)
                            .lineLimit(1)
                    }
                }
            }
            .padding(16)
            .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 10))

            Button("Open Settings\u{2026}") {
                (NSApp.delegate as? AppDelegate)?.openSettingsWindow()
            }
            .buttonStyle(.link)
            .font(.caption)

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Recording Popover (Onboarding)

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
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
            }

            if viewModel.hotkeyRecorder.isPendingReady {
                EmptyView()
            } else if let conflict = viewModel.hotkeyRecorder.pendingConflict {
                Text(conflict)
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Text("Recording...")
                    .font(.callout)
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

    // MARK: - Helpers

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 24)
            Text(text)
                .font(.callout)
        }
    }
}

#Preview {
    OnboardingView()
}
