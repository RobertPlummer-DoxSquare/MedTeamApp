import SwiftUI

struct ProposalCardView: View {
    let card: ProposalCard

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "testtube.2")
                    .font(.caption).foregroundColor(.researchPurple)
                Text("Research Proposal")
                    .font(.caption).fontWeight(.semibold).foregroundColor(.researchPurple)
                Spacer()
                Text("Submitted")
                    .font(.caption2).fontWeight(.medium)
                    .foregroundColor(.researchPurple)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.researchPurpleBackground)
                    .cornerRadius(6)
            }

            Divider().background(Color.nmaBorder)

            if let topic    = card.topic       { row("Topic", topic) }
            if let stage    = card.stage       { row("Stage", stage.rawValue) }
            if let role     = card.roleNeeded  { row("Role Needed", role) }
            if let timeline = card.timeline    { row("Timeline", timeline) }
        }
        .padding(14)
        .background(Color.nmaSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color.nmaBorder, lineWidth: 0.5))
    }

    private func row(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key).font(.caption).foregroundColor(.nmaSecondary)
            Spacer()
            Text(value).font(.caption).fontWeight(.medium).foregroundColor(.nmaPrimary)
        }
    }
}
