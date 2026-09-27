import SwiftUI

struct ProposalCardFormView: View {
    let onSubmit: (ProposalCard) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var topic = ""
    @State private var stage: ProposalCard.ResearchStage = .concept
    @State private var roleNeeded = ""
    @State private var timeline = ""

    private var isValid: Bool {
        !topic.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nmaBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Share the key details of your research so your collaborator can evaluate the fit.")
                            .font(.subheadline)
                            .foregroundColor(.nmaSecondary)
                            .padding(.top, 4)

                        field("Research Topic",
                              placeholder: "e.g. AI-assisted sepsis prediction",
                              text: $topic)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("CURRENT STAGE")
                                .font(.caption).foregroundColor(.nmaSecondary).tracking(1)
                            Picker("Stage", selection: $stage) {
                                ForEach(ProposalCard.ResearchStage.allCases, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.nmaPrimary)
                            .padding(12)
                            .background(Color.nmaSurface)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.nmaBorder, lineWidth: 0.5))
                        }

                        field("Role Needed",
                              placeholder: "e.g. Co-investigator, biostatistician",
                              text: $roleNeeded)
                        field("Estimated Timeline",
                              placeholder: "e.g. 18 months",
                              text: $timeline)

                        Button {
                            var card = ProposalCard()
                            card.topic = topic.isEmpty ? nil : topic
                            card.stage = stage
                            card.roleNeeded = roleNeeded.isEmpty ? nil : roleNeeded
                            card.timeline = timeline.isEmpty ? nil : timeline
                            card.isSubmitted = true
                            onSubmit(card)
                            dismiss()
                        } label: {
                            Text("Submit Proposal")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .background(isValid ? Color.nmaPrimary : Color.nmaSubtle)
                                .foregroundColor(isValid ? .white : .nmaSecondary)
                                .cornerRadius(12)
                        }
                        .disabled(!isValid)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Research Proposal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.nmaSecondary)
                }
            }
        }
    }

    private func field(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.caption).foregroundColor(.nmaSecondary).tracking(1)
            TextField(placeholder, text: text)
                .foregroundColor(.nmaPrimary)
                .padding(12)
                .background(Color.nmaSurface)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.nmaBorder, lineWidth: 0.5))
        }
    }
}
