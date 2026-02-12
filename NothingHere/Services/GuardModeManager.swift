//
//  GuardModeManager.swift
//  NothingHere
//

import AppKit
import OSLog

private let logger = Logger(subsystem: "boli.NothingHere", category: "GuardMode")

@Observable
final class GuardModeManager {

    static let shared = GuardModeManager()

    private(set) var isArmed = false

    var onGuardTriggered: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isTapEnabled = true

    private init() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(hotkeyRecordingDidStart),
            name: .hotkeyRecordingDidStart, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(hotkeyRecordingDidEnd),
            name: .hotkeyRecordingDidEnd, object: nil
        )
    }

    // MARK: - Public API

    func arm() {
        guard !isArmed else { return }
        if createEventTap() {
            isArmed = true
            logger.info("Guard mode armed")
        } else {
            logger.error("Failed to arm guard mode — Accessibility permission may be missing")
            NotificationCenter.default.post(name: .accessibilityPermissionNeeded, object: nil)
        }
    }

    func disarm() {
        guard isArmed else { return }
        destroyEventTap()
        isArmed = false
        logger.info("Guard mode disarmed")
    }

    func toggle() {
        if isArmed {
            disarm()
        } else {
            arm()
        }
    }

    // MARK: - CGEvent Tap

    private func createEventTap() -> Bool {
        destroyEventTap()

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let callback: CGEventTapCallBack = { _, _, event, userInfo in
            guard let userInfo else { return Unmanaged.passUnretained(event) }
            let manager = Unmanaged<GuardModeManager>.fromOpaque(userInfo).takeUnretainedValue()

            DispatchQueue.main.async {
                manager.disarm()
                manager.onGuardTriggered?()
            }

            return nil // swallow the key event
        }

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: callback,
            userInfo: selfPtr
        )

        guard let eventTap else { return false }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        isTapEnabled = true

        return true
    }

    private func destroyEventTap() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
            self.eventTap = nil
            self.runLoopSource = nil
            isTapEnabled = false
        }
    }

    // MARK: - Hotkey Recording Pause/Resume

    @objc private func hotkeyRecordingDidStart() {
        guard isArmed, let eventTap else { return }
        CGEvent.tapEnable(tap: eventTap, enable: false)
        isTapEnabled = false
        logger.info("Guard mode tap paused for hotkey recording")
    }

    @objc private func hotkeyRecordingDidEnd() {
        guard isArmed, let eventTap else { return }
        CGEvent.tapEnable(tap: eventTap, enable: true)
        isTapEnabled = true
        logger.info("Guard mode tap resumed after hotkey recording")
    }
}
