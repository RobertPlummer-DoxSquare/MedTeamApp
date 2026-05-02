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
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Complete these details so the receiving physician can prepare.")
                            .font(.subheadline)
                            .foregroundColor(Color(white: 0.45))
                            .padding(.top, 4)

                        field("Patient Age", placeholder: "e.g. 67", text: $patientAge)
                            .keyboardType(.numberPad)
                        field("Diagnosis", placeholder: "Primary diagnosis", text: $diagnosis)
                        field("Reason for Referral",
                              placeholder: "What do you need from this specialist?",
                              text: $reason)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("URGENCY")
                                .font(.caption).foregroundColor(Color(white: 0.4)).tracking(1)
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
                                .background(isValid ? Color.white : Color(white: 0.15))
                                .foregroundColor(isValid ? .black : Color(white: 0.35))
                                .cornerRadius(12)
                        }
                        .disabled(!isValid)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Referral Details")
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
