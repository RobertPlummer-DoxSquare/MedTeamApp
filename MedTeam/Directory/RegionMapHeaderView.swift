import SwiftUI

struct RegionMapHeaderView: View {
    let region: NMARegion

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.nmaSubtle
            NMAMapView(highlightedRegion: region)
                .frame(height: 220)
            regionCard
                .padding(.horizontal, 16)
                .padding(.bottom, -20)
        }
        .frame(height: 220)
        .background(Color.nmaSubtle)
    }

    private var regionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color.regionBlueBackground)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(regionNumeral)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.regionBlue)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(region.fullDisplayName)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(Color.nmaPrimary)
                    Text(region.statesDisplay)
                        .font(.caption2)
                        .foregroundColor(Color.nmaSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Text(region.chairName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.regionBlue)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.regionBlueBackground)
                    .cornerRadius(6)
            }

            if region.nextMeeting != "TBD" {
                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(Color.regionBlue)
                    Text(region.nextMeeting)
                        .font(.caption2)
                        .foregroundColor(Color.nmaSecondary)
                }
                .padding(.leading, 48)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Color.nmaSurface)
        .cornerRadius(12)
        .shadow(color: Color.nmaPrimary.opacity(0.12), radius: 10, x: 0, y: 3)
    }

    private var regionNumeral: String {
        switch region {
        case .regionI:   return "I"
        case .regionII:  return "II"
        case .regionIII: return "III"
        case .regionIV:  return "IV"
        case .regionV:   return "V"
        case .regionVI:  return "VI"
        }
    }
}
