import Foundation
import FirebaseFirestore

@MainActor
class ConversationListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    private var listener: ListenerRegistration?

    func startListening() {
        listener = MessagingService.shared.fetchConversations { [weak self] convos in
            self?.conversations = convos
        }
    }

    func stopListening() {
        listener?.remove()
    }
}
