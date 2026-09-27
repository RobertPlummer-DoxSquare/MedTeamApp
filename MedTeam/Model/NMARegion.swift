//
//  NMARegion.swift
//  MedTeam
//

import SwiftUI
import UIKit

enum NMARegion: String, Codable, CaseIterable {
    case regionI   = "Region I"
    case regionII  = "Region II"
    case regionIII = "Region III"
    case regionIV  = "Region IV"
    case regionV   = "Region V"
    case regionVI  = "Region VI"

    var displayName: String { rawValue }

    var subtitle: String {
        switch self {
        case .regionI:   return "Northeast"
        case .regionII:  return "Mid-Atlantic"
        case .regionIII: return "Southeast"
        case .regionIV:  return "Midwest"
        case .regionV:   return "South & Southwest"
        case .regionVI:  return "West & Pacific"
        }
    }

    var fullDisplayName: String { "\(rawValue) — \(subtitle)" }

    var chairSpecialty: String {
        switch self {
        case .regionI:   return "Internal Medicine"
        case .regionII:  return "Cardiology"
        case .regionIII: return "Pediatrics"
        case .regionIV:  return "General Surgery"
        case .regionV:   return "Family Medicine"
        case .regionVI:  return "Oncology"
        }
    }

    var highlightColor: Color {
        switch self {
        case .regionI:   return Color(hex: "1565C0")
        case .regionII:  return Color(hex: "B71C1C")
        case .regionIII: return Color(hex: "1B5E20")
        case .regionIV:  return Color(hex: "4A148C")
        case .regionV:   return Color(hex: "E65100")
        case .regionVI:  return Color(hex: "006064")
        }
    }

    var highlightUIColor: UIColor {
        switch self {
        case .regionI:   return UIColor(red: 0.082, green: 0.396, blue: 0.753, alpha: 1)
        case .regionII:  return UIColor(red: 0.714, green: 0.110, blue: 0.110, alpha: 1)
        case .regionIII: return UIColor(red: 0.106, green: 0.369, blue: 0.125, alpha: 1)
        case .regionIV:  return UIColor(red: 0.290, green: 0.078, blue: 0.549, alpha: 1)
        case .regionV:   return UIColor(red: 0.902, green: 0.318, blue: 0.000, alpha: 1)
        case .regionVI:  return UIColor(red: 0.000, green: 0.376, blue: 0.392, alpha: 1)
        }
    }

    var states: [String] {
        switch self {
        case .regionI:   return ["CT","ME","MA","NH","NJ","NY","PR","RI","VT","VI"]
        case .regionII:  return ["DE","DC","MD","PA","VA","WV"]
        case .regionIII: return ["AL","FL","GA","KY","MS","NC","SC","TN"]
        case .regionIV:  return ["IL","IN","MI","MN","OH","WI"]
        case .regionV:   return ["AR","IA","KS","LA","MO","NE","NM","OK","TX"]
        case .regionVI:  return ["AK","AZ","CA","CO","HI","ID","MT","NV","ND","OR","SD","UT","WA","WY"]
        }
    }

    var statesDisplay: String { states.joined(separator: " · ") }

    // Full state names as used in the us-atlas topology (properties.name)
    var fullStateNames: [String] {
        switch self {
        case .regionI:
            return ["New York", "New Jersey", "Connecticut", "Massachusetts",
                    "Rhode Island", "Vermont", "New Hampshire", "Maine"]
        case .regionII:
            return ["Delaware", "District of Columbia", "Maryland",
                    "Pennsylvania", "Virginia", "West Virginia"]
        case .regionIII:
            return ["Alabama", "Florida", "Georgia", "Kentucky",
                    "Mississippi", "North Carolina", "South Carolina", "Tennessee"]
        case .regionIV:
            return ["Illinois", "Indiana", "Michigan", "Minnesota", "Ohio", "Wisconsin"]
        case .regionV:
            return ["Arkansas", "Iowa", "Kansas", "Louisiana", "Missouri",
                    "Nebraska", "New Mexico", "Oklahoma", "Texas"]
        case .regionVI:
            return ["Alaska", "Arizona", "California", "Colorado", "Hawaii", "Idaho",
                    "Montana", "Nevada", "North Dakota", "Oregon", "South Dakota",
                    "Utah", "Washington", "Wyoming"]
        }
    }

    var chairName: String {
        switch self {
        case .regionI:   return "Dr. Monique Jones"
        case .regionII:  return "Dr. Carole Guy"
        case .regionIII: return "Dr. Ninita Brown"
        case .regionIV:  return "Dr. Lindi Randall Hayes"
        case .regionV:   return "Dr. Derick Young"
        case .regionVI:  return "Dr. L. Khadijah K. Lang"
        }
    }

    var nextMeeting: String {
        switch self {
        case .regionI:   return "May 21–25, 2026 · St. Thomas"
        case .regionII:  return "April 16–18, 2026 · Pittsburgh, PA"
        case .regionIII: return "April 10–12, 2026 · Baton Rouge, LA"
        case .regionIV:  return "May 1–3, 2026 · Cleveland, OH"
        case .regionV:   return "April 10–12, 2026 · Baton Rouge, LA"
        case .regionVI:  return "TBD"
        }
    }

    var badgeBackground: Color {
        switch self {
        case .regionI:   return Color(hex: "FFF3CD")
        case .regionII:  return Color(hex: "FFE0E0")
        case .regionIII: return Color(hex: "D4EDDA")
        case .regionIV:  return Color(hex: "E8E0FF")
        case .regionV:   return Color(hex: "FFF3E0")
        case .regionVI:  return Color(hex: "E8F4F8")
        }
    }

    var badgeForeground: Color {
        switch self {
        case .regionI:   return Color(hex: "7A5C00")
        case .regionII:  return Color(hex: "8B1A1A")
        case .regionIII: return Color(hex: "155724")
        case .regionIV:  return Color(hex: "3C2D8A")
        case .regionV:   return Color(hex: "7A4000")
        case .regionVI:  return Color(hex: "1A4A6B")
        }
    }

    static func fromState(_ state: String) -> NMARegion? {
        NMARegion.allCases.first { $0.states.contains(state) }
    }
}

enum NMARegionRole: String, Codable {
    case member      = "Member"
    case officer     = "Officer"
    case chairperson = "Chairperson"
}
