import Foundation

struct SavedRaceEntry: Identifiable, Codable {
    var id: UUID
    let event: RaceEvent
    var targetPace: String? // e.g., "5:00" min/km
    var targetSpeed: Double? // e.g., 12.0 km/h
    var notes: String?
    var strategy: RaceStrategy? // Persist the calculated strategy
    var preparation: RacePreparation? // Full race preparation data
    
    init(event: RaceEvent, targetPace: String? = nil, targetSpeed: Double? = nil, notes: String? = nil, strategy: RaceStrategy? = nil, preparation: RacePreparation? = nil) {
        self.id = UUID()
        self.event = event
        self.targetPace = targetPace
        self.targetSpeed = targetSpeed
        self.notes = notes
        self.strategy = strategy
        self.preparation = preparation
    }
    
    var displayGoal: String {
        if let pace = targetPace {
            return "\(pace) min/km"
        } else if let speed = targetSpeed {
            return String(format: "%.1f km/h", speed)
        }
        return "No goal set"
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: event.date)
        return max(0, components.day ?? 0)
    }
    
    var weeksRemaining: Int {
        return daysRemaining / 7
    }
    
    var progressPercentage: Double {
        // Assume training starts ~16 weeks before race
        let totalDays = 112.0 // 16 weeks
        let daysElapsed = totalDays - Double(daysRemaining)
        return min(1.0, max(0.0, daysElapsed / totalDays))
    }
    
    var motivationalMessage: String {
        switch daysRemaining {
        case 0: return "Race day! 🏁 You've got this!"
        case 1...7: return "Final week! Taper and trust your training 💪"
        case 8...14: return "Almost there! Stay focused 🎯"
        case 15...30: return "Training on track! 🏃‍♂️"
        case 31...60: return "Building strength every day 💪"
        default: return "The journey begins! 🚀"
        }
    }
}
