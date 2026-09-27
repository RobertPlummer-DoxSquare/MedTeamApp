import FirebaseFirestore
import FirebaseFirestoreSwift

struct Conversation: Identifiable, Codable {
    @DocumentID var id: String?
    let pingId: String?          // legacy: conversations created from pings
    var requesterId: String?     // who sent the request (nil on legacy threads)
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
    var lastMessageSenderId: String?
    var lastReadAt: [String: Date]?

    enum CodingKeys: String, CodingKey {
        case id, pingId, requesterId, type, participantIds, status
        case createdAt, lastMessage, lastMessageAt, lastMessageSenderId, lastReadAt
        case referralCard, proposalCard, participantNames
    }

    /// Legacy threads have no requesterId; their first participant started them.
    var requester: String? { requesterId ?? participantIds.first }

    func isRequester(_ uid: String) -> Bool { requester == uid }

    func otherParticipantId(for uid: String) -> String? {
        participantIds.first { $0 != uid }
    }

    /// Unread when someone else wrote after this user last opened the thread.
    /// Legacy threads (no lastMessageSenderId) count as read.
    func isUnread(for uid: String) -> Bool {
        guard let senderId = lastMessageSenderId, senderId != uid,
              let last = lastMessageAt else { return false }
        guard let read = lastReadAt?[uid] else { return true }
        return last > read
    }
}

enum ConversationStatus: String, Codable {
    case pending   = "pending"    // request waiting for the receiver
    case active    = "active"     // accepted (and all legacy threads)
    case declined  = "declined"
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
