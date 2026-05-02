//
//  PingViewModel.swift
//  MedTeam
//

import Foundation

@MainActor
class PingViewModel: ObservableObject {
    @Published var isSending = false
    @Published var didSend = false
    @Published var error: String?

    let targetUser: User

    init(targetUser: User) {
        self.targetUser = targetUser
    }

    var availablePingTypes: [PingType] {
        var types: [PingType] = []
        if targetUser.isAcceptingReferrals  { types.append(.referral) }
        if targetUser.isMentor              { types.append(.mentorship) }
        if targetUser.isOpenToCollaboration { types.append(.collaboration) }
        return types
    }

    func sendPing(type: PingType, note: String) async {
        isSending = true
        defer { isSending = false }
        do {
            try await PingService.shared.sendPing(to: targetUser.id, type: type, note: note)
            didSend = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}
