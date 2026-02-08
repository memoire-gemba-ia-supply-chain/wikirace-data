import SwiftUI

struct FilterButton: View {
    let title: String
    let iconName: String?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.themeBlue : Color.gray.opacity(0.1)) // Using themeBlue
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}

struct DistanceBadge: View {
    let distance: Distance
    
    var color: Color {
        switch distance {
        case .fiveKm, .tenKm: return .themeGreen
        case .halfMarathon, .marathon: return .themeBlue
        case .ultraTrail: return .themeOrange
        case .halfIronman, .ironman: return .themeRed
        }
    }
    
    var body: some View {
        Text(distance.rawValue)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

struct EventCard: View {
    let event: RaceEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.discipline.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.themeTextSecondary)
                    
                    Text(event.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.themeTextPrimary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Date Banner
                VStack {
                    Text(event.date, format: .dateTime.month())
                        .font(.caption)
                        .fontWeight(.bold)
                        .textCase(.uppercase)
                        .foregroundColor(.red)
                    Text(event.date, format: .dateTime.day())
                        .font(.title3)
                        .fontWeight(.black)
                    Text(event.date, format: .dateTime.year()) // Added Year
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Info Row: Distance | Price
            HStack(spacing: 12) {
                DistanceBadge(distance: event.distance)
                
                if event.price != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "banknote")
                            .font(.caption)
                        Text(event.formattedPrice)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            Divider()
            
            HStack {
                HStack(spacing: 4) {
                    Text(event.flagEmoji)
                    Text(event.country)
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                }
                
                Spacer()
                
                if let elevation = event.elevationGain {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.right")
                        Text("\(elevation)m")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.themeCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.themeBlue)
            
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
