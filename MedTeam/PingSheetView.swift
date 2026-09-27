//
//  PingSheetView.swift
//  MedTeam
//

import SwiftUI

struct PingSheetView: View {
    @StateObject private var viewModel: PingViewModel
    @State private var selectedType: PingType?
    @State private var note = ""
    @Environment(\.dismiss) private var dismiss

    init(targetUser: User) {
        _viewModel = StateObject(wrappedValue: PingViewModel(targetUser: targetUser))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.nmaBackground.ignoresSafeArea()
                if viewModel.didSend {
                    sentConfirmationView
                } else {
                    selectionView
                }
            }
            .navigationTitle("Message \(viewModel.targetUser.fullname)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.nmaSecondary)
                }
            }
        }
    }

    private var selectionView: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Available for:")
                    .font(.subheadline).foregroundColor(Color.nmaSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20).padding(.top, 20)

                ForEach(viewModel.availablePingTypes, id: \.self) { type in
                    PingTypeRow(type: type, isSelected: selectedType == type)
                        .onTapGesture { selectedType = type }
                        .padding(.horizontal, 16)
                }

                if selectedType != .referral {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Add a note (optional)")
                            .font(.caption).foregroundColor(Color.nmaSecondary)
                        TextEditor(text: $note)
                            .frame(height: 80)
                            .padding(10)
                            .background(Color.nmaSurface)
                            .cornerRadius(10)
                            .foregroundColor(Color.nmaPrimary)
                            .scrollContentBackground(.hidden)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.nmaBorder, lineWidth: 0.5))
                    }
                    .padding(.horizontal, 16).padding(.top, 8)
                }

                Button {
                    guard let type = selectedType else { return }
                    Task { await viewModel.sendPing(type: type, note: note) }
                } label: {
                    Group {
                        if viewModel.isSending {
                            ProgressView().tint(.white)
                        } else {
                            Text(sendButtonTitle).fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(selectedType != nil ? Color.nmaPrimary : Color.nmaSubtle)
                    .foregroundColor(selectedType != nil ? .white : Color.nmaSecondary)
                    .cornerRadius(12)
                }
                .disabled(selectedType == nil || viewModel.isSending)
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 40)
            }
        }
    }

    private var sendButtonTitle: String {
        switch selectedType {
        case .referral:      return "Send Referral Notification"
        case .mentorship:    return "Request Mentorship"
        case .collaboration: return "Start Collaboration Thread"
        case nil:            return "Send"
        }
    }

    private var sentConfirmationView: some View {
        let isThread = viewModel.sentType != .referral
        let firstName = viewModel.targetUser.fullname.components(separatedBy: " ").first
            ?? viewModel.targetUser.fullname
        return VStack(spacing: 16) {
            Circle()
                .fill(isThread ? Color.nmaPrimary.opacity(0.08) : Color.green.opacity(0.1))
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: isThread ? "message.fill" : "checkmark")
                        .font(.title2)
                        .foregroundColor(isThread ? Color.nmaPrimary : .green)
                )
            Text(isThread ? "Thread opened" : "Referral notification sent")
                .font(.title3).fontWeight(.semibold).foregroundColor(Color.nmaPrimary)
            Text(isThread
                ? "Your conversation with Dr. \(firstName) is waiting in your Messages tab."
                : "\(firstName) has been notified and will call your office to coordinate care.")
                .font(.subheadline).foregroundColor(Color.nmaSecondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Button("Done") { dismiss() }
                .foregroundColor(Color.nmaSecondary).padding(.top, 8)
        }
    }
}

// MARK: - Ping Type Row

struct PingTypeRow: View {
    let type: PingType
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: type.iconSystemName)
                .font(.system(size: 16))
                .foregroundColor(isSelected ? Color.nmaPrimary : Color.nmaSecondary)
                .frame(width: 36, height: 36)
                .background(isSelected ? Color.nmaPrimary.opacity(0.08) : Color.nmaSubtle)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(type.displayName)
                    .font(.subheadline).fontWeight(.medium).foregroundColor(Color.nmaPrimary)
                Text(type.description)
                    .font(.caption).foregroundColor(Color.nmaSecondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.nmaPrimary)
            }
        }
        .padding(14)
        .background(Color.nmaSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.nmaPrimary.opacity(0.3) : Color.nmaBorder, lineWidth: 0.5)
        )
    }
}
