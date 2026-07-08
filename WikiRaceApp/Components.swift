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
    
    var disciplineColor: Color {
        switch event.discipline {
        case .running: return .themeBlue
        case .trail: return .themeOrange
        case .triathlon: return .themeRed
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Accent Bar (Discipline Color)
            Rectangle()
                .fill(disciplineColor)
                .frame(width: 6)
            
            VStack(alignment: .leading, spacing: 12) {
                // Header Row: Discipline + Name + Date Box
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: event.discipline.iconName)
                                .font(.system(size: 10, weight: .black))
                            Text(event.discipline.rawValue.uppercased())
                                .font(.system(size: 10, weight: .black))
                        }
                        .foregroundColor(disciplineColor)
                        
                        Text(event.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.themeTextPrimary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    // Date Box
                    VStack(spacing: 2) {
                        Text(event.date, format: .dateTime.day())
                            .font(.system(size: 18, weight: .black))
                        Text(event.date, format: .dateTime.month(.abbreviated))
                            .font(.system(size: 10, weight: .bold))
                            .textCase(.uppercase)
                    }
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(disciplineColor)
                    )
                }
                
                // Info Row: Distance + Elevation + Price
                HStack(spacing: 12) {
                    DistanceBadge(distance: event.distance)
                    
                    if let elevation = event.elevationGain {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up.right")
                            Text("\(elevation)m")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.themeTextSecondary)
                    }
                    
                    Spacer()
                    
                    if event.price != nil {
                        Text(event.formattedPrice)
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.themeTextPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.themeGreen.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                
                // Footer Row: Location
                HStack {
                    HStack(spacing: 4) {
                        Text(event.flagEmoji)
                        Text("\(event.city), \(event.country)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.themeTextSecondary)
                    }
                    
                    Spacer()
                }
            }
            .padding(14)
        }
        .background(Color.themeCardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.themeBlue.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
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
