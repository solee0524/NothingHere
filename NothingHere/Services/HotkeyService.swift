//
//  HotkeyService.swift
//  NothingHere
//

import AppKit
import Carbon.HIToolbox
import OSLog

private let logger = Logger(subsystem: "boli.NothingHere", category: "Hotkey")

protocol HotkeyServiceProtocol {
    func register(keyCode: UInt16, modifiers: UInt32)
    func unregister()
}

final class HotkeyService: HotkeyServiceProtocol {

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    var onHotkeyTriggered: (() -> Void)?

    func register(keyCode: UInt16, modifiers: UInt32) {
        unregister()

        guard keyCode != 0 || modifiers != 0 else {
            logger.info("No hotkey configured, skipping registration")
            return
        }

        let expectedModifiers = NSEvent.ModifierFlags(rawValue: UInt(modifiers))
            .intersection(.deviceIndependentFlagsMask)

        let callback: CGEventTapCallBack = { _, _, event, userInfo in
            guard let userInfo else { return Unmanaged.passUnretained(event) }
            let service = Unmanaged<HotkeyService>.fromOpaque(userInfo).takeUnretainedValue()

            let eventKeyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            let eventFlags = NSEvent.ModifierFlags(rawValue: UInt(event.flags.rawValue))
                .intersection(.deviceIndependentFlagsMask)

            let storedKeyCode = UInt16(UserDefaults.standard.integer(forKey: "hotkeyKeyCode"))
            let storedModifiers = NSEvent.ModifierFlags(
                rawValue: UInt(UserDefaults.standard.integer(forKey: "hotkeyModifiers"))
            ).intersection(.deviceIndependentFlagsMask)

            if eventKeyCode == storedKeyCode && eventFlags == storedModifiers {
                logger.info("Hotkey triggered")
                DispatchQueue.main.async {
                    service.onHotkeyTriggered?()
                }
            }

            return Unmanaged.passUnretained(event)
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: callback,
            userInfo: selfPtr
        )

        guard let eventTap else {
            logger.error("Failed to create event tap — Accessibility permission may be missing")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        let display = KeyCodeMapper.displayString(keyCode: keyCode, modifiers: modifiers)
        logger.info("Registered global hotkey: \(display)")
    }

    func unregister() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
            self.eventTap = nil
            self.runLoopSource = nil
            logger.info("Unregistered global hotkey")
        }
    }

    deinit {
        unregister()
    }
}
