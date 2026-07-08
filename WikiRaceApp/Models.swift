import Foundation
import SwiftUI

enum Discipline: String, CaseIterable, Codable {
    case running = "Running"
    case trail = "Trail"
    case triathlon = "Triathlon"
    
    var iconName: String {
        switch self {
        case .running: return "figure.run"
        case .trail: return "mountain.2"
        case .triathlon: return "figure.swim" // Placeholder, SF Symbols might not have a perfect tri icon, often used combination or generic
        }
    }
}

enum Distance: String, CaseIterable, Codable {
    case fiveKm = "5km"
    case tenKm = "10km"
    case halfMarathon = "Half Marathon"
    case marathon = "Marathon"
    case ultraTrail = "Ultra Trail"
    case halfIronman = "Half Ironman"
    case ironman = "Ironman"
    
    var badgeColorName: String {
        switch self {
        case .fiveKm, .tenKm: return "themeGreen"
        case .halfMarathon, .marathon: return "themeBlue"
        case .ultraTrail: return "themeOrange"
        case .halfIronman, .ironman: return "themeRed"
        }
    }
}

enum RegistrationStatus: String, Codable {
    case open = "Open"
    case closed = "Closed"
    case soldOut = "Sold Out"
    case unknown = "Unknown"
    
    var color: Color {
        switch self {
        case .open: return .themeGreen
        case .closed: return .themeRed
        case .soldOut: return .themeOrange
        case .unknown: return .gray
        }
    }
}

struct RaceEvent: Identifiable, Codable {
    let id: UUID
    let name: String
    let date: Date
    let city: String
    let country: String
    let countryCode: String // For flag emoji/image
    let discipline: Discipline
    let distance: Distance
    let elevationGain: Int? // In meters
    var description: String
    let registrationUrl: URL
    let imageUrl: String // Placeholder for asset name or URL
    
    // New Fields
    var price: Double? // Price in local currency or USD/EUR
    let currency: String? // "EUR", "USD", etc.
    var registrationStatus: RegistrationStatus?
    
    // Helper for formatting date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var formattedPrice: String {
        guard let price = price, let currency = currency else { return "TBD" }
        return "\(price) \(currency)"
    }
    
    var flagEmoji: String {
        countryCode
            .unicodeScalars
            .map { 127397 + $0.value }
            .compactMap { UnicodeScalar($0) }
            .map { String($0) }
            .joined()
    }
}

// MARK: - Localization Helper
extension String {
    var localized: String {
        // In a Swift Package, resources are in Bundle.module
        // In a standard app, they are in Bundle.main
        // We try to find the module bundle or fallback to main
        let bundle: Bundle
        #if SWIFT_PACKAGE
        bundle = Bundle.module
        #else
        bundle = Bundle.main
        #endif
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}

// MARK: - Localized Keys
public struct AppStrings {
    // Tab Bar
    static let tabExplore = "tab.explore".localized
    static let tabCalendar = "tab.calendar".localized
    
    // Home
    static let homeTitle = "home.title".localized
    static func eventsCount(_ count: Int) -> String {
        "home.events_count".localized(with: count)
    }
    static let sortAsc = "home.sort.asc".localized
    static let sortDesc = "home.sort.desc".localized
    
    // Filters
    static let filterRunning = "filter.running".localized
    static let filterTrail = "filter.trail".localized
    static let filterTriathlon = "filter.triathlon".localized
    
    // Detail
    static let detailAbout = "detail.about".localized
    static let detailRegister = "detail.register".localized
    static let detailAddCalendar = "detail.add_calendar".localized
    static let detailPrice = "detail.price".localized
    static let detailDistance = "detail.distance".localized
    static let detailDate = "detail.date".localized
    
    // Goal Sheet
    static let goalTitle = "goal.title".localized
    static let goalType = "goal.type".localized
    static let goalPace = "goal.pace".localized
    static let goalSpeed = "goal.speed".localized
    static let goalTarget = "goal.target".localized
    static let goalNotes = "goal.notes".localized
    static let goalAdd = "goal.add".localized
    static let goalCancel = "goal.cancel".localized
    
    // My Events
    static let myEventsTitle = "myevents.title".localized
    static let myEventsEmpty = "myevents.empty".localized
    static let myEventsEmptySubtitle = "myevents.empty_subtitle".localized
    static let myEventsDays = "myevents.days".localized
    static let myEventsTarget = "myevents.target".localized
    static let myEventsRemove = "myevents.remove".localized
    
    // Status
    static let statusOpen = "status.open".localized
    static let statusClosed = "status.closed".localized
    static let statusSoldOut = "status.soldout".localized
    
    // Alerts
    static let alertAdded = "alert.added".localized
    static let alertAddedMessage = "alert.added_message".localized
    static let alertOK = "alert.ok".localized
    
    // Preparation Screen
    static let prepDaysToGo = "prep.days_to_go".localized
    static let prepStrategy = "prep.strategy".localized
    static let prepNutrition = "prep.nutrition".localized
    static let prepTraining = "prep.training".localized
    static let prepChecklist = "prep.checklist".localized
    static let prepRemove = "prep.remove".localized
    
    // Results & History
    static let resultNeedsResult = "result.needs_result".localized
    static let resultUpcoming = "result.upcoming".localized
    static let resultHistory = "result.history".localized
    static let resultDidFinishPrompt = "result.did_finish_prompt".localized
    static let resultFinished = "result.finished".localized
    static let resultDNF = "result.dnf".localized
    static let resultCompletion = "result.completion".localized
    static let resultDidFinish = "result.did_finish".localized
    static let resultYes = "result.yes".localized
    static let resultNo = "result.no".localized
    static let resultFinishTime = "result.finish_time".localized
    static let resultSaveResult = "result.save_result".localized
}

// MARK: - Race Strategy Models
struct RaceStrategy: Codable, Identifiable {
    var id: UUID = UUID()
    var targetTime: TimeInterval
    var variation: Double // -0.1 to 0.1 (Negative to Positive Split)
    var splits: [RaceSplit]
    var nutritionPlan: [NutritionItem]
}

struct RaceSplit: Codable, Identifiable {
    var id: UUID = UUID()
    var kilometer: Int
    var time: TimeInterval
    var cumulativeTime: TimeInterval
    
    var formattedPace: String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedCumulative: String {
        let hours = Int(cumulativeTime) / 3600
        let minutes = (Int(cumulativeTime) % 3600) / 60
        let seconds = Int(cumulativeTime) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct NutritionItem: Codable, Identifiable {
    var id: UUID = UUID()
    var timeOffset: TimeInterval
    var type: NutritionType
    var description: String
    
    enum NutritionType: String, Codable {
        case water = "Water"
        case gel = "Energy Gel"
        case salt = "Salt Tablet"
        case food = "Solid Food"
        case caffeine = "Caffeine"
    }
    
    var formattedTime: String {
        let hours = Int(timeOffset) / 3600
        let minutes = (Int(timeOffset) % 3600) / 60
        return String(format: "%dh%02d", hours, minutes)
    }
}

// MARK: - Calculator
class RaceStrategyCalculator {
    
    static func calculateSplits(distanceKm: Double, targetTime: TimeInterval, variation: Double) -> [RaceSplit] {
        var splits: [RaceSplit] = []
        let averagePace = targetTime / distanceKm
        
        let startFactor = 1.0 - (variation * 0.1) // If var = -1 (Neg Split), Factor = 1.1 (Slower start)
        let endFactor = 1.0 + (variation * 0.1)   // If var = -1 (Neg Split), Factor = 0.9 (Faster end)
        
        let slope = (endFactor - startFactor) / distanceKm
        
        var currentCumulative: TimeInterval = 0
        
        // Round distance to ceiling for integer kilometers
        let totalKm = Int(ceil(distanceKm))
        
        for km in 1...totalKm {
            // Calculate pace factor for this specific kilometer
            let kmFactor = startFactor + (slope * Double(km))
            
            let splitTime = averagePace * kmFactor
            currentCumulative += splitTime
            
            splits.append(RaceSplit(kilometer: km, time: splitTime, cumulativeTime: currentCumulative))
        }
        
        // Normalize to exact target time if needed (optional, good for precision)
        let calculatedTotal = splits.last?.cumulativeTime ?? 0
        if calculatedTotal > 0 {
            let ratio = targetTime / calculatedTotal
            for i in 0..<splits.count {
                splits[i].time *= ratio
                if i == 0 {
                    splits[i].cumulativeTime = splits[i].time
                } else {
                    splits[i].cumulativeTime = splits[i-1].cumulativeTime + splits[i].time
                }
            }
        }
        
        return splits
    }
    
    static func generateNutritionPlan(duration: TimeInterval) -> [NutritionItem] {
        var plan: [NutritionItem] = []
        
        // Basic Marathon/Ultra logic
        // - Hydration every 15-20 min (approx 5km aid stations)
        // - Gels every 45-60 min
        
        // Hydration loop (every 20 mins)
        for t in stride(from: 1200.0, to: duration, by: 1200.0) { // 20 mins
            plan.append(NutritionItem(timeOffset: t, type: .water, description: "Drink 150-200ml Water/Electrolytes"))
        }
        
        // Fuel loop (every 45 mins)
        // Start taking gels after 45 mins
        for t in stride(from: 2700.0, to: duration - 1800, by: 2700.0) { // 45 mins, stop 30m before finish
            plan.append(NutritionItem(timeOffset: t, type: .gel, description: "Take Energy Gel (20-30g Carbs)"))
        }
        
        // Salt loop (for longer events > 3h, every hour)
        if duration > 10800 {
            for t in stride(from: 3600.0, to: duration, by: 3600.0) {
                plan.append(NutritionItem(timeOffset: t, type: .salt, description: "Take Salt Tablet (if hot/sweating)"))
            }
        }
        
        // Sort by time
        plan.sort { $0.timeOffset < $1.timeOffset }
        
        return plan
    }
}

// MARK: - Training Models

enum FitnessLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var weeklyVolume: Double { // Base km per week
        switch self {
        case .beginner: return 25
        case .intermediate: return 45
        case .advanced: return 70
        }
    }
}

enum WorkoutType: String, CaseIterable, Codable {
    case easyRun = "Easy Run"
    case tempo = "Tempo"
    case intervals = "Intervals"
    case longRun = "Long Run"
    case rest = "Rest Day"
    case strength = "Strength"
    case crossTrain = "Cross Train"
    case warmUp = "Warm Up"
    case coolDown = "Cool Down"
    case hillRepeats = "Hill Repeats"
    case trailRun = "Trail Run"
    case progressionRun = "Progression Run"
    case fartlek = "Fartlek"
    
    var color: String {
        switch self {
        case .easyRun, .warmUp, .coolDown: return "themeBlue"
        case .tempo, .progressionRun: return "themeOrange"
        case .intervals, .hillRepeats, .fartlek: return "themeRed"
        case .longRun, .trailRun: return "themeGreen"
        case .rest: return "gray"
        case .strength: return "purple"
        case .crossTrain: return "teal"
        }
    }
    
    var icon: String {
        switch self {
        case .easyRun: return "figure.run"
        case .tempo: return "speedometer"
        case .intervals: return "bolt.fill"
        case .longRun: return "mountain.2.fill"
        case .rest: return "bed.double.fill"
        case .strength: return "dumbbell.fill"
        case .crossTrain: return "figure.pool.swim"
        case .warmUp: return "flame.fill"
        case .coolDown: return "snowflake"
        case .hillRepeats: return "arrow.up.circle.fill"
        case .trailRun: return "leaf.fill"
        case .progressionRun: return "chart.line.uptrend.xyaxis"
        case .fartlek: return "hare.fill"
        }
    }
}

struct Workout: Identifiable, Codable {
    var id: UUID = UUID()
    var type: WorkoutType
    var title: String
    var description: String
    var date: Date
    var durationMinutes: Int
    var distanceKm: Double?
    var isCompleted: Bool = false
    var warmUpMinutes: Int = 10
    var coolDownMinutes: Int = 5
    
    var formattedDuration: String {
        if durationMinutes >= 60 {
            let hours = durationMinutes / 60
            let mins = durationMinutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(durationMinutes)m"
    }
    
    var formattedDistance: String {
        guard let km = distanceKm else { return "" }
        return String(format: "%.1f km", km)
    }
}

struct TrainingWeek: Identifiable, Codable {
    var id: UUID = UUID()
    var weekNumber: Int
    var startDate: Date
    var workouts: [Workout]
    var focus: String // e.g., "Base Building", "Peak Week", "Taper"
    
    var completedCount: Int {
        workouts.filter { $0.isCompleted }.count
    }
    
    var totalWorkouts: Int {
        workouts.filter { $0.type != .rest }.count
    }
    
    var totalDistanceKm: Double {
        workouts.compactMap { $0.distanceKm }.reduce(0, +)
    }
    
    var completionPercentage: Double {
        guard totalWorkouts > 0 else { return 0 }
        return Double(completedCount) / Double(totalWorkouts)
    }
}

struct HealthLog: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var weight: Double // in kg
    var bodyFatPercentage: Double? // optional
    var feeling: Int // 1-10
}

struct TrainingPlan: Identifiable, Codable {
    var id: UUID = UUID()
    var raceDistance: Distance
    var targetTime: TimeInterval?
    var goalPace: TimeInterval? // Seconds per km
    var fitnessLevel: FitnessLevel
    var startDate: Date
    var raceDate: Date
    var weeks: [TrainingWeek]
    
    var totalWeeks: Int { weeks.count }
    
    var currentWeekIndex: Int {
        let today = Date()
        return weeks.firstIndex { week in
            let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: week.startDate) ?? week.startDate
            return today >= week.startDate && today <= endOfWeek
        } ?? 0
    }
    
    var currentWeek: TrainingWeek? {
        guard currentWeekIndex < weeks.count else { return nil }
        return weeks[currentWeekIndex]
    }
    
    var overallProgress: Double {
        let totalWorkouts = weeks.flatMap { $0.workouts }.filter { $0.type != .rest }.count
        let completed = weeks.flatMap { $0.workouts }.filter { $0.isCompleted }.count
        guard totalWorkouts > 0 else { return 0 }
        return Double(completed) / Double(totalWorkouts)
    }
}

// MARK: - Race Day Checklist

struct ChecklistItem: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var category: ChecklistCategory
    var isChecked: Bool = false
    var notes: String?
}

enum ChecklistCategory: String, CaseIterable, Codable {
    case gear = "Gear"
    case nutrition = "Nutrition"
    case travel = "Travel"
    case pacing = "Pacing Strategy"
    
    var icon: String {
        switch self {
        case .gear: return "tshirt.fill"
        case .nutrition: return "fork.knife"
        case .travel: return "car.fill"
        case .pacing: return "gauge.high"
        }
    }
}

struct RaceChecklist: Codable {
    var items: [ChecklistItem]
    
    static var defaultChecklist: RaceChecklist {
        RaceChecklist(items: [
            // Gear
            ChecklistItem(title: "Running shoes", category: .gear),
            ChecklistItem(title: "Race bib & pins", category: .gear),
            ChecklistItem(title: "GPS watch", category: .gear),
            ChecklistItem(title: "Race outfit", category: .gear),
            ChecklistItem(title: "Sunglasses/hat", category: .gear),
            ChecklistItem(title: "Body glide/vaseline", category: .gear),
            // Nutrition
            ChecklistItem(title: "Energy gels", category: .nutrition),
            ChecklistItem(title: "Electrolyte drink", category: .nutrition),
            ChecklistItem(title: "Pre-race breakfast", category: .nutrition),
            ChecklistItem(title: "Post-race snacks", category: .nutrition),
            // Travel
            ChecklistItem(title: "Race packet pickup", category: .travel),
            ChecklistItem(title: "Know the start location", category: .travel),
            ChecklistItem(title: "Bag drop plan", category: .travel),
            ChecklistItem(title: "Post-race meeting point", category: .travel),
            // Pacing
            ChecklistItem(title: "Review splits plan", category: .pacing),
            ChecklistItem(title: "Fueling schedule set", category: .pacing),
            ChecklistItem(title: "Know aid station locations", category: .pacing),
        ])
    }
    
    var completedCount: Int {
        items.filter { $0.isChecked }.count
    }
    
    var totalCount: Int {
        items.count
    }
}

// MARK: - Race Preparation (aggregates all prep data)

struct RacePreparation: Codable {
    var targetFinishTime: TimeInterval?
    var targetPacePerKm: TimeInterval? // seconds per km
    var fitnessLevel: FitnessLevel = .intermediate
    
    var personalNotes: String = ""
    var motivationQuote: String = ""
    var trainingPlan: TrainingPlan?
    var checklist: RaceChecklist = .defaultChecklist
    
    var formattedTargetTime: String {
        guard let time = targetFinishTime else { return "Not set" }
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    
    var formattedTargetPace: String {
        guard let pace = targetPacePerKm else { return "Not set" }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d min/km", minutes, seconds)
    }
}

enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
}

// MARK: - Global User Profile
struct UserProfile: Codable {
    var heightCm: Double?
    var birthDate: Date?
    var gender: Gender?
    var healthLogs: [HealthLog] = []
    
    static var empty: UserProfile {
        UserProfile(heightCm: nil, birthDate: nil, gender: nil, healthLogs: [])
    }
}

