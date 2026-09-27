//
//  PingInboxViewModel.swift
//  MedTeam
//

import Foundation
import FirebaseFirestore

@MainActor
class PingInboxViewModel: ObservableObject {
    @Published var receivedPings: [Ping] = []
    @Published var sentPings: [Ping] = []
    @Published var unreadCount: Int = 0

    private var receivedListener: ListenerRegistration?
    private var sentListener: ListenerRegistration?

    func startListening() {
        receivedListener = PingService.shared.fetchReceivedPings { [weak self] pings in
            guard let self else { return }
            Task { @MainActor in
                self.receivedPings = pings
                self.unreadCount = PingService.shared.unreadCount(from: pings)
            }
        }
        sentListener = PingService.shared.fetchSentPings { [weak self] pings in
            guard let self else { return }
            Task { @MainActor in
                self.sentPings = pings
            }
        }
    }

    func stopListening() {
        receivedListener?.remove()
        sentListener?.remove()
    }
}
