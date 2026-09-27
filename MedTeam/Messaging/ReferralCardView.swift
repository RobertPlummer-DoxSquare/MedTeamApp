import SwiftUI

struct ReferralCardView: View {
    let card: ReferralCard
    let canConfirm: Bool
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.caption).foregroundColor(.referralGreen)
                Text("Referral Details")
                    .font(.caption).fontWeight(.semibold).foregroundColor(.referralGreen)
                Spacer()
                statusBadge
            }

            Divider().background(Color.nmaBorder)

            if let age = card.patientAge { row("Patient Age", "\(age) yrs") }
            if let dx  = card.diagnosis  { row("Diagnosis", dx) }
            if let r   = card.reasonForReferral { row("Reason", r) }
            if let urg = card.urgency {
                HStack {
                    Text("Urgency").font(.caption).foregroundColor(.nmaSecondary)
                    Spacer()
                    Text(urg.rawValue)
                        .font(.caption).fontWeight(.medium)
                        .foregroundColor(urgencyColor(urg))
                }
            }
            if let ins = card.insurance { row("Insurance", ins) }

            if canConfirm {
                Button(action: onConfirm) {
                    Text("Confirm Acceptance")
                        .font(.subheadline).fontWeight(.semibold)
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .background(Color.referralGreenBackground)
                        .foregroundColor(.referralGreen)
                        .cornerRadius(10)
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(Color.nmaSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color.nmaBorder, lineWidth: 0.5))
    }

    private var statusBadge: some View {
        Text(card.isConfirmed ? "Confirmed" : "Awaiting confirmation")
            .font(.caption2).fontWeight(.medium)
            .foregroundColor(card.isConfirmed ? .referralGreen : .pendingAmber)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(card.isConfirmed ? Color.referralGreenBackground : Color.pendingAmberBackground)
            .cornerRadius(6)
    }

    private func row(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key).font(.caption).foregroundColor(.nmaSecondary)
            Spacer()
            Text(value).font(.caption).fontWeight(.medium).foregroundColor(.nmaPrimary)
        }
    }

    private func urgencyColor(_ u: ReferralCard.ReferralUrgency) -> Color {
        switch u {
        case .routine:  return .referralGreen
        case .urgent:   return .pendingAmber
        case .emergent: return .red
        }
    }
}
