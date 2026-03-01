//
//  AppTypography.swift
//  NothingHere
//

import SwiftUI

/// Centralized font management. To switch the global font, modify `fontName(for:)`.
enum AppTypography {

    // MARK: - Font Configuration (single point of change)

    /// Switch the app font by changing the return values here.
    private static func fontName(for weight: Font.Weight) -> String {
        switch weight {
        case .light:     return "Poppins-Light"
        case .regular:   return "Poppins-Regular"
        case .medium:    return "Poppins-Medium"
        case .semibold:  return "Poppins-SemiBold"
        case .bold:      return "Poppins-Bold"
        case .heavy:     return "Poppins-ExtraBold"
        default:         return "Poppins-Regular"
        }
    }

    /// Base method: custom font with size and weight.
    static func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(fontName(for: weight), size: size)
    }

    // MARK: - Semantic Typography Scale

    // Display
    static let displayLarge  = font(size: 32, weight: .semibold)
    static let displayMedium = font(size: 26, weight: .bold)

    // Heading
    static let headingLarge  = font(size: 20, weight: .semibold)
    static let headingMedium = font(size: 16, weight: .bold)
    static let headingSmall  = font(size: 14, weight: .bold)

    // Body
    static let bodyLarge  = font(size: 16)
    static let bodyMedium = font(size: 14)
    static let bodySmall  = font(size: 12)

    // Label
    static let labelLarge  = font(size: 13, weight: .bold)
    static let labelMedium = font(size: 12, weight: .bold)
    static let labelSmall  = font(size: 11, weight: .semibold)

    // Button
    static let buttonLarge  = font(size: 13, weight: .semibold)
    static let buttonMedium = font(size: 12, weight: .medium)
    static let buttonSmall  = font(size: 10, weight: .heavy)

    // Caption
    static let captionLarge  = font(size: 10)
    static let captionMedium = font(size: 9)
    static let captionSmall  = font(size: 8, weight: .heavy)
    static let captionTiny   = font(size: 7, weight: .bold)

    // MARK: - Keycap (SF system font for hotkey badges)

    static func keycap(size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
