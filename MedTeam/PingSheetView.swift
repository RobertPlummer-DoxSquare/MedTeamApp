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
                Color.black.ignoresSafeArea()
                if viewModel.didSend {
                    sentConfirmationView
                } else {
                    pingSelectionView
                }
            }
            .navigationTitle("Ping \(viewModel.targetUser.fullname)")
            .navigationBarTitleDisplayMode(.inline)
            .colorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(white: 0.5))
                }
            }
        }
    }

    private var pingSelectionView: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Available for:")
                    .font(.subheadline)
                    .foregroundColor(Color(white: 0.45))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                ForEach(viewModel.availablePingTypes, id: \.self) { type in
                    PingTypeRow(type: type, isSelected: selectedType == type)
                        .onTapGesture { selectedType = type }
                        .padding(.horizontal, 16)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Add a note (optional)")
                        .font(.caption)
                        .foregroundColor(Color(white: 0.45))
                    TextEditor(text: $note)
                        .frame(height: 80)
                        .padding(10)
                        .background(Color(white: 0.1))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Button {
                    guard let type = selectedType else { return }
                    Task { await viewModel.sendPing(type: type, note: note) }
                } label: {
                    Group {
                        if viewModel.isSending {
                            ProgressView().tint(.black)
                        } else {
                            Text("Send Ping").fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(selectedType != nil ? Color.white : Color(white: 0.2))
                    .foregroundColor(selectedType != nil ? .black : Color(white: 0.4))
                    .cornerRadius(12)
                }
                .disabled(selectedType == nil || viewModel.isSending)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
    }

    private var sentConfirmationView: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(Color.green.opacity(0.15))
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .foregroundColor(.green)
                )
            Text("Ping sent")
                .font(.title3).fontWeight(.semibold).foregroundColor(.white)
            Text("They'll be notified and can accept or decline from their pings inbox.")
                .font(.subheadline)
                .foregroundColor(Color(white: 0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Done") { dismiss() }
                .foregroundColor(Color(white: 0.5))
                .padding(.top, 8)
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
                .foregroundColor(type.color)
                .frame(width: 36, height: 36)
                .background(type.color.opacity(0.12))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(type.displayName)
                    .font(.subheadline).fontWeight(.medium).foregroundColor(.white)
                Text(type.description)
                    .font(.caption).foregroundColor(Color(white: 0.45))
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(type.color)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? type.color.opacity(0.1) : Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? type.color.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        )
    }
}
