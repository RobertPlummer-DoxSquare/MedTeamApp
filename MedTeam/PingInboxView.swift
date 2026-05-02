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
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    Picker("", selection: $tab) {
                        Text("Received").tag(InboxTab.received)
                        Text("Sent").tag(InboxTab.sent)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    Divider().background(Color(white: 0.15))

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            let pings = tab == .received ? viewModel.receivedPings : viewModel.sentPings
                            if pings.isEmpty {
                                emptyState
                            } else {
                                ForEach(pings) { ping in
                                    PingRowView(
                                        ping: ping,
                                        isReceived: tab == .received,
                                        onAccept: { Task { await viewModel.accept(ping) } },
                                        onDecline: { Task { await viewModel.decline(ping) } }
                                    )
                                    Divider().background(Color(white: 0.1)).padding(.leading, 16)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Pings")
            .navigationBarTitleDisplayMode(.inline)
            .colorScheme(.dark)
        }
        .onAppear { viewModel.startListening() }
        .onDisappear { viewModel.stopListening() }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .font(.largeTitle)
                .foregroundColor(Color(white: 0.3))
            Text("No pings yet")
                .foregroundColor(Color(white: 0.4))
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - Ping Row

struct PingRowView: View {
    let ping: Ping
    let isReceived: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(ping.type.color)
                    .frame(width: 10, height: 10)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(isReceived ? (ping.fromUser?.fullname ?? "Unknown") : (ping.toUser?.fullname ?? "Unknown"))
                            .font(.subheadline).fontWeight(.medium).foregroundColor(.white)
                        Spacer()
                        Text(ping.createdAt.timeAgoDisplay())
                            .font(.caption2).foregroundColor(Color(white: 0.4))
                    }

                    Text(ping.type.displayName)
                        .font(.caption).foregroundColor(ping.type.color)

                    if let note = ping.note {
                        Text("\"\(note)\"")
                            .font(.caption).foregroundColor(Color(white: 0.5))
                            .lineLimit(2)
                    }

                    if isReceived && ping.status == .pending {
                        HStack(spacing: 8) {
                            Button("Accept", action: onAccept)
                                .font(.caption).fontWeight(.medium)
                                .padding(.horizontal, 14).padding(.vertical, 6)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                            Button("Decline", action: onDecline)
                                .font(.caption)
                                .foregroundColor(Color(white: 0.4))
                        }
                        .padding(.top, 2)
                    } else {
                        statusBadge
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var statusBadge: some View {
        Text(ping.status.rawValue.capitalized)
            .font(.caption2)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(statusColor.opacity(0.1))
            .cornerRadius(6)
    }

    private var statusColor: Color {
        switch ping.status {
        case .pending:  return .orange
        case .accepted: return .green
        case .declined: return Color(white: 0.4)
        }
    }
}
