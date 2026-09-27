import SwiftUI

struct ReferralCardFormView: View {
    let onSubmit: (ReferralCard) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var patientAge = ""
    @State private var diagnosis = ""
    @State private var reason = ""
    @State private var urgency: ReferralCard.ReferralUrgency = .routine
    @State private var insurance = ""

    private var isValid: Bool {
        !diagnosis.trimmingCharacters(in: .whitespaces).isEmpty &&
        !reason.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nmaBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Complete these details so the receiving physician can prepare.")
                            .font(.subheadline)
                            .foregroundColor(.nmaSecondary)
                            .padding(.top, 4)

                        field("Patient Age", placeholder: "e.g. 67", text: $patientAge)
                            .keyboardType(.numberPad)
                        field("Diagnosis", placeholder: "Primary diagnosis", text: $diagnosis)
                        field("Reason for Referral",
                              placeholder: "What do you need from this specialist?",
                              text: $reason)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("URGENCY")
                                .font(.caption).foregroundColor(.nmaSecondary).tracking(1)
                            Picker("Urgency", selection: $urgency) {
                                ForEach(ReferralCard.ReferralUrgency.allCases, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        field("Insurance", placeholder: "e.g. Medicare (optional)", text: $insurance)

                        Button {
                            var card = ReferralCard()
                            card.patientAge = Int(patientAge)
                            card.diagnosis = diagnosis.isEmpty ? nil : diagnosis
                            card.reasonForReferral = reason.isEmpty ? nil : reason
                            card.urgency = urgency
                            card.insurance = insurance.isEmpty ? nil : insurance
                            onSubmit(card)
                            dismiss()
                        } label: {
                            Text("Submit Referral Details")
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
            .navigationTitle("Referral Details")
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
