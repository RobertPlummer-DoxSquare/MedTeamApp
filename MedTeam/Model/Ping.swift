//
//  Ping.swift
//  MedTeam
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Ping: Identifiable, Codable {
    @DocumentID var id: String?
    let fromUserId: String
    let toUserId: String
    let type: PingType
    let note: String?
    var status: PingStatus
    let createdAt: Date
    var readAt: Date?

    var fromUser: User?
    var toUser: User?

    enum CodingKeys: String, CodingKey {
        case id, fromUserId, toUserId, type, note, status, createdAt, readAt
    }
}

enum PingType: String, Codable, CaseIterable {
    case referral      = "referral"
    case mentorship    = "mentorship"
    case collaboration = "collaboration"

    var displayName: String {
        switch self {
        case .referral:      return "Referral"
        case .mentorship:    return "Mentorship"
        case .collaboration: return "Research Collaboration"
        }
    }

    var description: String {
        switch self {
        case .referral:      return "Send a patient referral request"
        case .mentorship:    return "Request mentorship or guidance"
        case .collaboration: return "Propose a research partnership"
        }
    }

    var iconSystemName: String {
        switch self {
        case .referral:      return "arrow.triangle.branch"
        case .mentorship:    return "person.2.fill"
        case .collaboration: return "testtube.2"
        }
    }

    var color: Color {
        switch self {
        case .referral:      return .green
        case .mentorship:    return .blue
        case .collaboration: return .purple
        }
    }

    var accentColor: Color { color }
}

enum PingStatus: String, Codable {
    case pending  = "pending"
    case accepted = "accepted"
    case declined = "declined"
}
