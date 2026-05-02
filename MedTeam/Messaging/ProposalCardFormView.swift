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
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Share the key details of your research so your collaborator can evaluate the fit.")
                            .font(.subheadline)
                            .foregroundColor(Color(white: 0.45))
                            .padding(.top, 4)

                        field("Research Topic",
                              placeholder: "e.g. AI-assisted sepsis prediction",
                              text: $topic)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("CURRENT STAGE")
                                .font(.caption).foregroundColor(Color(white: 0.4)).tracking(1)
                            Picker("Stage", selection: $stage) {
                                ForEach(ProposalCard.ResearchStage.allCases, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                            .padding(12)
                            .background(Color(white: 0.08))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(white: 0.15), lineWidth: 0.5))
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
                                .background(isValid ? Color.white : Color(white: 0.15))
                                .foregroundColor(isValid ? .black : Color(white: 0.35))
                                .cornerRadius(12)
                        }
                        .disabled(!isValid)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Research Proposal")
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

    private func field(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.caption).foregroundColor(Color(white: 0.4)).tracking(1)
            TextField(placeholder, text: text)
                .foregroundColor(.white)
                .padding(12)
                .background(Color(white: 0.08))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(white: 0.15), lineWidth: 0.5))
        }
    }
}
