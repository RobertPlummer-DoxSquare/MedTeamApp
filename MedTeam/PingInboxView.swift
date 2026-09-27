//
//  PingInboxView.swift
//  MedTeam
//

import SwiftUI

struct PingInboxView: View {
    @StateObject private var viewModel = PingInboxViewModel()
    @State private var tab: InboxTab = .received

    enum InboxTab { case received, sent }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nmaBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    Picker("", selection: $tab) {
                        Text("Received").tag(InboxTab.received)
                        Text("Sent").tag(InboxTab.sent)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16).padding(.vertical, 12)

                    Divider().foregroundColor(Color.nmaBorder)

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            let pings = tab == .received ? viewModel.receivedPings : viewModel.sentPings
                            if pings.isEmpty {
                                emptyState
                            } else {
                                ForEach(pings) { ping in
                                    PingRowView(ping: ping, isReceived: tab == .received)
                                    Divider().background(Color.nmaBorder).padding(.leading, 16)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { viewModel.startListening() }
        .onDisappear { viewModel.stopListening() }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash").font(.largeTitle).foregroundColor(Color.nmaSecondary)
            Text("No notifications yet").foregroundColor(Color.nmaSecondary).font(.subheadline)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }
}

// MARK: - Ping Row

struct PingRowView: View {
    let ping: Ping
    let isReceived: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 10, height: 10)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(isReceived
                            ? (ping.fromUser?.fullname ?? "Unknown")
                            : (ping.toUser?.fullname ?? "Unknown"))
                            .font(.subheadline).fontWeight(.medium).foregroundColor(Color.nmaPrimary)
                        Spacer()
                        Text(ping.createdAt.timeAgoDisplay())
                            .font(.caption2).foregroundColor(Color.nmaSecondary)
                    }

                    Text(ping.type.displayName)
                        .font(.caption).foregroundColor(typeColor)

                    if let note = ping.note, ping.type != .referral {
                        Text("\"\(note)\"")
                            .font(.caption).foregroundColor(Color.nmaSecondary).lineLimit(2)
                    }

                    if isReceived {
                        receivedFooter
                    } else {
                        sentStatusBadge
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color.nmaBackground)
    }

    private var typeColor: Color { ping.type.color }

    @ViewBuilder
    private var receivedFooter: some View {
        if ping.type == .referral {
            referralReceivedFooter
        } else {
            threadReceivedFooter
        }
    }

    private var referralReceivedFooter: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let specialty = ping.fromUser?.specialty {
                Text(specialty).font(.caption).foregroundColor(Color.nmaSecondary)
            }
            if let institution = ping.fromUser?.currentInstitution, !institution.isEmpty {
                Text(institution).font(.caption).foregroundColor(Color.nmaSecondary.opacity(0.75))
            }
            if let phone = ping.fromUser?.officePhone, !phone.isEmpty {
                Label(phone, systemImage: "phone")
                    .font(.caption).foregroundColor(Color.referralGreen)
            }
            Text("Contact their office to coordinate care.")
                .font(.caption).italic().foregroundColor(Color.nmaSecondary.opacity(0.7))
        }
        .padding(.top, 2)
    }

    private var threadReceivedFooter: some View {
        Button {
            NotificationCenter.default.post(name: .switchToMessages, object: nil)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "message.fill").font(.caption2)
                Text("View thread in Messages").font(.caption)
            }
            .foregroundColor(Color.nmaPrimary)
        }
        .padding(.top, 2)
    }

    private var sentStatusBadge: some View {
        let (label, color, bg) = sentBadgeInfo
        return Text(label)
            .font(.caption2).foregroundColor(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(bg).cornerRadius(6)
    }

    private var sentBadgeInfo: (String, Color, Color) {
        switch (ping.type, ping.status) {
        case (.referral, _):  return ("Notification sent", Color.nmaSecondary, Color.nmaSubtle)
        case (_, .accepted):  return ("Thread open", Color.referralGreen, Color.referralGreenBackground)
        case (_, .pending):   return ("Pending", Color.pendingAmber, Color.pendingAmberBackground)
        case (_, .declined):  return ("Declined", Color.nmaSecondary, Color.nmaSubtle)
        }
    }
}
