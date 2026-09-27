//
//  PingViewModel.swift
//  MedTeam
//

import Foundation
import FirebaseAuth

@MainActor
class PingViewModel: ObservableObject {
    @Published var isSending = false
    @Published var didSend = false
    @Published var sentType: PingType?
    @Published var error: String?

    let targetUser: User

    init(targetUser: User) {
        self.targetUser = targetUser
    }

    var availablePingTypes: [PingType] {
        var types: [PingType] = []
        if targetUser.isOpenToReferrals      { types.append(.referral) }
        if targetUser.isMentor              { types.append(.mentorship) }
        if targetUser.isOpenToCollaboration { types.append(.collaboration) }
        return types
    }

    func sendPing(type: PingType, note: String) async {
        isSending = true
        defer { isSending = false }
        do {
            let pingId = try await PingService.shared.sendPing(to: targetUser.id, type: type, note: note)

            if type != .referral {
                guard let fromUserId = Auth.auth().currentUser?.uid else { return }
                let fromUserName = UserService.shared.currentUser?.fullname ?? "Unknown"
                try await MessagingService.shared.createConversationForPing(
                    pingId: pingId,
                    fromUserId: fromUserId,
                    toUserId: targetUser.id,
                    type: type,
                    fromUserName: fromUserName,
                    toUserName: targetUser.fullname
                )
                try await PingService.shared.updateStatus(pingId, status: .accepted)
            }

            sentType = type
            didSend = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}
