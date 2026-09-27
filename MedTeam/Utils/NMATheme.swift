//
//  NMATheme.swift
//  MedTeam
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255)
    }

    static let nmaBackground = Color(hex: "F8F7F5")
    static let nmaSurface    = Color.white
    static let nmaPrimary    = Color(hex: "1A1A1A")
    static let nmaSecondary  = Color(hex: "888888")
    static let nmaBorder     = Color(hex: "E5E5E5")
    static let nmaSubtle     = Color(hex: "F2F2F2")

    // Accent colors, each with a light background for badges and chips.
    static let referralGreen            = Color(hex: "155724")
    static let referralGreenBackground  = Color(hex: "D4EDDA")
    static let researchPurple           = Color(hex: "3C2D8A")
    static let researchPurpleBackground = Color(hex: "E8E0FF")
    static let regionBlue               = Color(hex: "1D5C99")
    static let regionBlueBackground     = Color(hex: "EBF4FF")
    static let chairGold                = Color(hex: "7A5C00")
    static let chairGoldBackground      = Color(hex: "FFF3CD")
    static let pendingAmber             = Color(hex: "7A4000")
    static let pendingAmberBackground   = Color(hex: "FFF3E0")
}
