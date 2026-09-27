//
//  ConnectViewModel.swift
//  MedTeam
//

import Foundation

@MainActor
class ConnectViewModel: ObservableObject {
    @Published var isSending = false
    @Published var didSend = false
    @Published var errorMessage: String?

    let targetUser: User

    init(targetUser: User) {
        self.targetUser = targetUser
    }

    /// Referrals happen by phone, so only mentorship and collaboration are offered here.
    var availableTypes: [PingType] {
        var types: [PingType] = []
        if targetUser.isMentor              { types.append(.mentorship) }
        if targetUser.isOpenToCollaboration { types.append(.collaboration) }
        return types
    }

    func sendRequest(type: PingType, note: String) async {
        isSending = true
        defer { isSending = false }
        do {
            try await MessagingService.shared.sendRequest(
                to: targetUser,
                type: type,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            didSend = true
        } catch {
            errorMessage = AuthService.friendlyMessage(for: error)
        }
    }
}
