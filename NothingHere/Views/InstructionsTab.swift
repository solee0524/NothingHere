//
//  InstructionsTab.swift
//  NothingHere
//

import SwiftUI

struct InstructionsTab: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                quickStartSection
                guardModeSection
                coverDocumentSection
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Quick Start

    private var quickStartSection: some View {
        SettingsCard(header: "Quick Start") {
            VStack(alignment: .leading, spacing: 12) {
                instructionRow(
                    number: 1, color: .blue,
                    icon: "lock.shield",
                    text: "Grant Accessibility permission when prompted on first launch"
                )
                instructionRow(
                    number: 2, color: .blue,
                    icon: "keyboard",
                    text: "Set your Panic hotkey in General (e.g. \u{2303}\u{2325}\u{2318}H)"
                )
                instructionRow(
                    number: 3, color: .blue,
                    icon: "eye.slash",
                    text: "Press the hotkey \u{2014} all windows hide and media pauses instantly"
                )
            }
        }
    }

    // MARK: - Guard Mode

    private var guardModeSection: some View {
        SettingsCard(header: "Guard Mode") {
            VStack(alignment: .leading, spacing: 12) {
                instructionRow(
                    number: 1, color: .orange,
                    icon: "shield.lefthalf.filled",
                    text: "Arm Guard Mode from the menu bar or General tab"
                )
                instructionRow(
                    number: 2, color: .orange,
                    icon: "hand.tap",
                    text: "Press any key to trigger Panic \u{2014} no modifier needed"
                )
                instructionRow(
                    number: 3, color: .orange,
                    icon: "arrow.uturn.backward",
                    text: "Guard Mode disarms automatically after triggering"
                )
            }
        }
    }

    // MARK: - Cover Document

    private var coverDocumentSection: some View {
        SettingsCard(header: "Cover Document") {
            VStack(alignment: .leading, spacing: 12) {
                instructionRow(
                    number: 1, color: .green,
                    icon: "doc.badge.gearshape",
                    text: "Enable Cover Document in the General tab"
                )
                instructionRow(
                    number: 2, color: .green,
                    icon: "folder",
                    text: "Choose a decoy file to open as your cover"
                )
                instructionRow(
                    number: 3, color: .green,
                    icon: "doc.text",
                    text: "When Panic triggers, the file opens automatically"
                )
            }
        }
    }

    // MARK: - Instruction Row

    private func instructionRow(number: Int, color: Color, icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(color, in: Circle())

            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    InstructionsTab()
        .frame(width: 400, height: 500)
}
