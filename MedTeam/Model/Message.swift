import FirebaseFirestore
import FirebaseFirestoreSwift

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    let senderId: String
    let text: String
    let type: MessageType
    let createdAt: Date
    var readBy: [String]

    enum MessageType: String, Codable {
        case text
        case system
        case referralCard
        case proposalCard
    }

    enum CodingKeys: String, CodingKey {
        case id, senderId, text, type, createdAt, readBy
    }
}
