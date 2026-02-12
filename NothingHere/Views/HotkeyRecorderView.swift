//
//  HotkeyRecorderView.swift
//  NothingHere
//

import AppKit
import SwiftUI

/// An invisible NSView that captures key events — including modifier+key combos
/// (⌘Z, ⌘C, etc.) — before the menu system's `performKeyEquivalent:` consumes them.
/// This is the standard approach used by macOS shortcut recorders (MASShortcut, ShortcutRecorder).
struct HotkeyRecorderView: NSViewRepresentable {
    var onKeyDown: (NSEvent) -> Void
    var onFlagsChanged: (NSEvent) -> Void

    func makeNSView(context: Context) -> HotkeyRecorderNSView {
        let view = HotkeyRecorderNSView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: HotkeyRecorderNSView, context: Context) {
        context.coordinator.onKeyDown = onKeyDown
        context.coordinator.onFlagsChanged = onFlagsChanged

        // Defensively re-request first responder in case focus was lost
        DispatchQueue.main.async {
            if let window = nsView.window, window.firstResponder !== nsView {
                window.makeFirstResponder(nsView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onKeyDown: onKeyDown, onFlagsChanged: onFlagsChanged)
    }

    final class Coordinator {
        var onKeyDown: (NSEvent) -> Void
        var onFlagsChanged: (NSEvent) -> Void

        init(onKeyDown: @escaping (NSEvent) -> Void, onFlagsChanged: @escaping (NSEvent) -> Void) {
            self.onKeyDown = onKeyDown
            self.onFlagsChanged = onFlagsChanged
        }
    }
}

/// Custom NSView that intercepts keyboard events at the responder-chain level,
/// preventing the standard menu system from consuming modifier+key combinations.
final class HotkeyRecorderNSView: NSView {
    var coordinator: HotkeyRecorderView.Coordinator?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            guard let self, let window = self.window else { return }
            window.makeFirstResponder(self)
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        coordinator?.onKeyDown(event)
        return true
    }

    override func keyDown(with event: NSEvent) {
        coordinator?.onKeyDown(event)
    }

    override func flagsChanged(with event: NSEvent) {
        coordinator?.onFlagsChanged(event)
    }
}
