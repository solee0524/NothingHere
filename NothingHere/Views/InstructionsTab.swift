//
//  InstructionsTab.swift
//  NothingHere
//

import LucideIcons
import SwiftUI

// MARK: - Local Color Extension

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

// MARK: - Local Lucide Helper

private func lucideIcon(_ image: NSImage, size: CGFloat = 14) -> some View {
    Image(nsImage: image)
        .renderingMode(.template)
        .resizable()
        .frame(width: size, height: size)
}

// MARK: - Data Models

private struct InstructionStep {
    let number: Int
    let icon: NSImage
    let cardColor: Color
    let description: String
}

private struct InstructionSection {
    let title: String
    let titleIcon: NSImage
    let themeColor: Color
    let iconBgColor: Color
    let steps: [InstructionStep]
}

// MARK: - Section Data

private let sections: [InstructionSection] = [
    InstructionSection(
        title: "Quick Start",
        titleIcon: Lucide.zap,
        themeColor: Color(hex: 0x4584EE),
        iconBgColor: Color(hex: 0x0E244A),
        steps: [
            InstructionStep(
                number: 1,
                icon: Lucide.squareDashed,
                cardColor: Color(hex: 0x4584EE),
                description: "Required to hide windows and register global hotkey"
            ),
            InstructionStep(
                number: 2,
                icon: Lucide.keyboard,
                cardColor: Color(hex: 0x2E6AD0),
                description: "Set your Panic hotkey in General (e.g. ⌃⌘Z)"
            ),
            InstructionStep(
                number: 3,
                icon: Lucide.eyeOff,
                cardColor: Color(hex: 0x2354AA),
                description: "Press the hotkey - all windows hide and sound mutes instantly"
            ),
        ]
    ),
    InstructionSection(
        title: "Guard Mode",
        titleIcon: Lucide.shieldCheck,
        themeColor: Color(hex: 0xD54813),
        iconBgColor: Color(hex: 0x4E1B08),
        steps: [
            InstructionStep(
                number: 1,
                icon: Lucide.shield,
                cardColor: Color(hex: 0xD54813),
                description: "Arm Guard Mode from the menu bar or General tab"
            ),
            InstructionStep(
                number: 2,
                icon: Lucide.squareMousePointer,
                cardColor: Color(hex: 0xBB4317),
                description: "Press any key to trigger Panic - no modifier needed"
            ),
            InstructionStep(
                number: 3,
                icon: Lucide.shieldOff,
                cardColor: Color(hex: 0xA93D16),
                description: "Guard Mode disarms automatically after triggering"
            ),
        ]
    ),
    InstructionSection(
        title: "Cover Document",
        titleIcon: Lucide.files,
        themeColor: Color(hex: 0x17D952),
        iconBgColor: Color(hex: 0x074D1D),
        steps: [
            InstructionStep(
                number: 1,
                icon: Lucide.fileInput,
                cardColor: Color(hex: 0x17D952),
                description: "Enable Cover Document in the General tab"
            ),
            InstructionStep(
                number: 2,
                icon: Lucide.filePlus,
                cardColor: Color(hex: 0x1BC14C),
                description: "Choose a decoy file to open as your cover"
            ),
            InstructionStep(
                number: 3,
                icon: Lucide.maximize2,
                cardColor: Color(hex: 0x179A3E),
                description: "When Panic triggers, the file opens automatically"
            ),
        ]
    ),
]

// MARK: - InstructionsTab

struct InstructionsTab: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    sectionCard(section)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Section Card

    private func sectionCard(_ section: InstructionSection) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                lucideIcon(section.titleIcon, size: 16)
                    .foregroundStyle(section.themeColor)
                Text(section.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 12) {
                ForEach(Array(section.steps.enumerated()), id: \.offset) { _, step in
                    stepCard(step, iconBgColor: section.iconBgColor)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x111111), Color(hex: 0x000000)],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color(hex: 0x444444), lineWidth: 1)
        )
    }

    // MARK: - Step Card

    private func stepCard(_ step: InstructionStep, iconBgColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                lucideIcon(step.icon, size: 16)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(iconBgColor, in: Circle())
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("Step.\(step.number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text(step.description)
                    .font(.system(size: 10))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(minHeight: 120)
        .background(step.cardColor, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    InstructionsTab()
        .frame(width: 560, height: 500)
        .preferredColorScheme(.dark)
}
