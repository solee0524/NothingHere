//
//  OnboardingViewModel.swift
//  NothingHere
//

import AppKit
import OSLog

private let logger = Logger(subsystem: "boli.NothingHere", category: "Onboarding")

@Observable
final class OnboardingViewModel {

    enum Step: Int, CaseIterable {
        case welcome, permission, hotkey, document, done
    }

    // MARK: - State

    private(set) var currentStep: Step = .welcome
    private(set) var isAccessibilityGranted = false
    let hotkeyRecorder = HotkeyRecordingManager()
    let documentManager = CoverDocumentManager.shared

    var onComplete: (() -> Void)?

    // MARK: - Navigation

    var canProceed: Bool { true }

    var canGoBack: Bool {
        currentStep != .welcome
    }

    var isLastStep: Bool {
        currentStep == .done
    }

    func goNext() {
        guard let nextIndex = Step(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = nextIndex
        logger.info("Onboarding moved to step: \(nextIndex.rawValue)")
    }

    func goBack() {
        guard let prevIndex = Step(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prevIndex
    }

    func complete() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        logger.info("Onboarding completed")
        onComplete?()
    }

    // MARK: - Permission

    private let permissionService: PermissionServiceProtocol
    private var pollTimer: Timer?

    init(
        permissionService: PermissionServiceProtocol = PermissionService()
    ) {
        self.permissionService = permissionService
        self.isAccessibilityGranted = permissionService.isAccessibilityGranted
    }

    func grantPermission() {
        permissionService.requestAccessibility()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            self.isAccessibilityGranted = self.permissionService.isAccessibilityGranted
        }
    }

    func openPermissionSettings() {
        permissionService.openSystemSettings()
    }

    func startPermissionPolling() {
        stopPermissionPolling()
        isAccessibilityGranted = permissionService.isAccessibilityGranted
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            let wasGranted = self.isAccessibilityGranted
            self.isAccessibilityGranted = self.permissionService.isAccessibilityGranted
            if !wasGranted && self.isAccessibilityGranted {
                NotificationCenter.default.post(name: .accessibilityPermissionGranted, object: nil)
            }
        }
    }

    func stopPermissionPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    static var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}
