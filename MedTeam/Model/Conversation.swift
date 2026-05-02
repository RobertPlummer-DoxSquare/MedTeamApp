import FirebaseFirestore
import FirebaseFirestoreSwift

struct Conversation: Identifiable, Codable {
    @DocumentID var id: String?
    let pingId: String
    let type: PingType
    var participantIds: [String]
    var status: ConversationStatus
    let createdAt: Date
    var lastMessage: String?
    var lastMessageAt: Date?
    var referralCard: ReferralCard?
    var proposalCard: ProposalCard?
    var participantNames: [String: String]?
    var otherParticipantName: String?
    var otherParticipantCredentials: String?

    enum CodingKeys: String, CodingKey {
        case id, pingId, type, participantIds, status
        case createdAt, lastMessage, lastMessageAt
        case referralCard, proposalCard, participantNames
    }
}

enum ConversationStatus: String, Codable {
    case active    = "active"
    case completed = "completed"
    case archived  = "archived"
}

struct ReferralCard: Codable {
    var patientAge: Int?
    var diagnosis: String?
    var reasonForReferral: String?
    var urgency: ReferralUrgency?
    var insurance: String?
    var isConfirmed: Bool = false

    enum ReferralUrgency: String, Codable, CaseIterable {
        case routine  = "Routine"
        case urgent   = "Urgent"
        case emergent = "Emergent"
    }
}

struct ProposalCard: Codable {
    var topic: String?
    var stage: ResearchStage?
    var roleNeeded: String?
    var timeline: String?
    var isSubmitted: Bool = false

    enum ResearchStage: String, Codable, CaseIterable {
        case concept     = "Concept"
        case grantPending = "Grant Pending"
        case irbPending  = "IRB Pending"
        case enrolling   = "Active Enrollment"
        case analysis    = "Data Analysis"
    }
}
