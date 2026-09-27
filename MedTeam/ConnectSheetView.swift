//
//  ConnectSheetView.swift
//  MedTeam
//

import SwiftUI

struct ConnectSheetView: View {
    @StateObject private var viewModel: ConnectViewModel
    @State private var selectedType: PingType?
    @State private var note = ""
    @Environment(\.dismiss) private var dismiss

    init(targetUser: User) {
        _viewModel = StateObject(wrappedValue: ConnectViewModel(targetUser: targetUser))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nmaBackground.ignoresSafeArea()
                if viewModel.didSend {
                    sentConfirmationView
                } else {
                    selectionView
                }
            }
            .navigationTitle("Connect with \(viewModel.targetUser.formalName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel.didSend ? "Done" : "Cancel") { dismiss() }
                        .foregroundColor(Color.nmaPrimary)
                }
            }
        }
        .onAppear {
            if viewModel.availableTypes.count == 1 { selectedType = viewModel.availableTypes.first }
        }
    }

    private var selectionView: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("What would you like to ask for?")
                    .font(.subheadline).foregroundColor(Color.nmaSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20).padding(.top, 20)

                ForEach(viewModel.availableTypes, id: \.self) { type in
                    Button { selectedType = type } label: {
                        RequestTypeRow(type: type, isSelected: selectedType == type)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Add a note (optional)")
                        .font(.caption).foregroundColor(Color.nmaSecondary)
                    TextEditor(text: $note)
                        .frame(height: 90)
                        .padding(10)
                        .background(Color.nmaSurface)
                        .cornerRadius(10)
                        .foregroundColor(Color.nmaPrimary)
                        .scrollContentBackground(.hidden)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.nmaBorder, lineWidth: 0.5))
                    Label("Don't include patient information.", systemImage: "lock")
                        .font(.caption).foregroundColor(Color.nmaSecondary)
                }
                .padding(.horizontal, 16).padding(.top, 8)

                if let error = viewModel.errorMessage {
                    Text(error).font(.caption).foregroundColor(.red).padding(.horizontal, 16)
                }

                Button {
                    guard let type = selectedType else { return }
                    Task { await viewModel.sendRequest(type: type, note: note) }
                } label: {
                    Group {
                        if viewModel.isSending {
                            ProgressView().tint(.white)
                        } else {
                            Text("Send Request").fontWeight(.semibold)
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

    private var sentConfirmationView: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(Color.referralGreenBackground)
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .foregroundColor(.referralGreen)
                )
            Text("Request sent")
                .font(.title3).fontWeight(.semibold).foregroundColor(Color.nmaPrimary)
            Text("\(viewModel.targetUser.formalName) will see your request in their Inbox. You'll be able to message once they accept.")
                .font(.subheadline).foregroundColor(Color.nmaSecondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
        }
    }
}

// MARK: - Request Type Row

struct RequestTypeRow: View {
    let type: PingType
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: type.iconSystemName)
                .font(.system(size: 16))
                .foregroundColor(type.color)
                .frame(width: 36, height: 36)
                .background(type.color.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(type.displayName)
                    .font(.subheadline).fontWeight(.medium).foregroundColor(Color.nmaPrimary)
                Text(type.description)
                    .font(.caption).foregroundColor(Color.nmaSecondary)
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? Color.nmaPrimary : Color.nmaBorder)
        }
        .padding(14)
        .background(Color.nmaSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.nmaPrimary.opacity(0.4) : Color.nmaBorder, lineWidth: isSelected ? 1 : 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
