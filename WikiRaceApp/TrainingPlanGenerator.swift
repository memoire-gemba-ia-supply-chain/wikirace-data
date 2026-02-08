import Foundation

class TrainingPlanGenerator {
    static let shared = TrainingPlanGenerator()
    
    // MARK: - Core Generation Logic
    func generate(
        raceEvent: RaceEvent,
        fitnessLevel: FitnessLevel,
        goalPace: TimeInterval? // Seconds per km, optional
    ) -> TrainingPlan {
        let calendar = Calendar.current
        let today = Date()
        
        // 1. Calculate Duration
        let components = calendar.dateComponents([.weekOfYear], from: today, to: raceEvent.date)
        let weeksRemaining = max(4, components.weekOfYear ?? 12)
        // Cap max length to reasonable limits (e.g. 24 weeks) to avoid burnout
        let totalWeeks = min(24, weeksRemaining)
        
        var trainingWeeks: [TrainingWeek] = []
        
        // 2. Generate Weeks
        for w in 1...totalWeeks {
            let weekStartDate = calendar.date(byAdding: .day, value: -(totalWeeks - w) * 7, to: raceEvent.date) ?? Date()
            
            // Determine Phase
            let phase = determinePhase(week: w, totalWeeks: totalWeeks)
            
            // Generate Workouts for this week
            let workouts = generateWorkouts(
                for: weekStartDate,
                weekNumber: w,
                totalWeeks: totalWeeks,
                phase: phase,
                distance: raceEvent.distance,
                discipline: raceEvent.discipline,
                fitnessLevel: fitnessLevel,
                goalPace: goalPace
            )
            
            trainingWeeks.append(
                TrainingWeek(
                    weekNumber: w,
                    startDate: weekStartDate,
                    workouts: workouts,
                    focus: phase.rawValue
                )
            )
        }
        
        return TrainingPlan(
            raceDistance: raceEvent.distance,
            targetTime: nil, // Can be calculated from goalPace * distance
            goalPace: goalPace,
            fitnessLevel: fitnessLevel,
            startDate: trainingWeeks.first?.startDate ?? today,
            raceDate: raceEvent.date,
            weeks: trainingWeeks
        )
    }
    
    // MARK: - Phase Logic
    enum TrainingPhase: String {
        case base = "Base Building"
        case build = "Build"
        case peak = "Peak"
        case taper = "Taper"
    }
    
    private func determinePhase(week: Int, totalWeeks: Int) -> TrainingPhase {
        // Simple heuristic:
        // First 1/3 -> Base
        // Middle 1/3 (plus a bit) -> Build
        // Last 3-4 weeks -> Peak then Taper
        
        if week == totalWeeks || week == totalWeeks - 1 { return .taper }
        if week >= (totalWeeks - 4) { return .peak }
        
        let buildStart = totalWeeks / 3
        if week <= buildStart { return .base }
        return .build
    }
    
    // MARK: - Workout Generation
    private func generateWorkouts(
        for weekStartDate: Date,
        weekNumber: Int,
        totalWeeks: Int,
        phase: TrainingPhase,
        distance: Distance,
        discipline: Discipline,
        fitnessLevel: FitnessLevel,
        goalPace: TimeInterval?
    ) -> [Workout] {
        var workouts: [Workout] = []
        let calendar = Calendar.current
        
        // Volume Multiplier based on Fitness Level
        let volumeMult = getVolumeMultiplier(fitnessLevel)
        // Progression Factor (0.0 to 1.0)
        let progression = Double(weekNumber) / Double(totalWeeks - 2) // Peak at end-2
        
        // --- Weekly Template ---
        
        // 1. Monday: Rest or Cross Train (Beginner vs Advanced)
        if fitnessLevel == .advanced {
            workouts.append(createWorkout(type: .easyRun, title: "Recovery Run", dur: 30, date: weekStartDate, desc: "Very easy pace to flush legs."))
        } else {
            workouts.append(createWorkout(type: .rest, title: "Rest Day", dur: 0, date: weekStartDate, desc: "Rest and recover."))
        }
        
        // 2. Tuesday: Quality Session 1 (Intervals / Hills)
        let tueDate = calendar.date(byAdding: .day, value: 1, to: weekStartDate)!
        if discipline == .trail {
            // Trail focus: Hills
            workouts.append(createWorkout(type: .hillRepeats, title: "Hill Repeats", dur: 45 + (weekNumber * 2), date: tueDate, desc: "Run hard up, jog down. Build leg strength."))
        } else {
            // Road focus: Speed
            let intervalVolume = 4.0 + (Double(weekNumber) * 0.5 * volumeMult)
            let desc = goalPace != nil ? "Run at \((goalPace! - 15).formattedPace)/km" : "Hard effort (Zone 4/5)"
            workouts.append(createWorkout(type: .intervals, title: "Speed Intervals", dur: 50, date: tueDate, dist: intervalVolume, desc: desc))
        }
        
        // 3. Wednesday: Easy Volume
        let wedDate = calendar.date(byAdding: .day, value: 2, to: weekStartDate)!
        let wedDist = 5.0 + (Double(weekNumber) * 0.5 * volumeMult)
        workouts.append(createWorkout(type: .easyRun, title: "Aerobic Base", dur: Int(wedDist * 6), date: wedDate, dist: wedDist, desc: "conversational pace, Zone 2."))
        
        // 4. Thursday: Quality Session 2 (Tempo / Strength)
        let thuDate = calendar.date(byAdding: .day, value: 3, to: weekStartDate)!
        if phase == .base {
             workouts.append(createWorkout(type: .strength, title: "Strength & Conditioning", dur: 45, date: thuDate, desc: "Focus on global body strength"))
        } else {
            let tempoDist = 4.0 + (Double(weekNumber) * 0.5 * volumeMult)
            let desc = goalPace != nil ? "Target pace: \(goalPace!.formattedPace)/km" : "Comfortably hard (Zone 3/4)"
            workouts.append(createWorkout(type: .tempo, title: "Tempo Run", dur: 0, date: thuDate, dist: tempoDist, desc: desc))
        }
        
        // 5. Friday: Rest / Mobility
        let friDate = calendar.date(byAdding: .day, value: 4, to: weekStartDate)!
        workouts.append(createWorkout(type: .rest, title: "Mobility / Rest", dur: 20, date: friDate, desc: "Stretching and foam rolling."))
        
        // 6. Saturday: Long Run (The big one)
        let satDate = calendar.date(byAdding: .day, value: 5, to: weekStartDate)!
        var longRunDist = getBaseLongRun(distance) + ((getMaxLongRun(distance) - getBaseLongRun(distance)) * progression) * volumeMult
        
        // Taper Logic
        if phase == .taper {
            if weekNumber == totalWeeks { longRunDist *= 0.3 } // Race week
            else { longRunDist *= 0.6 } // Week before
        }
        
        let lrType: WorkoutType = (discipline == .trail) ? .trailRun : .longRun
        workouts.append(createWorkout(type: lrType, title: "Long Run", dur: Int(longRunDist * 6.5), date: satDate, dist: longRunDist, desc: "Build endurance. Manage fueling."))
        
        // 7. Sunday: Cross Train / Active Recovery
        let sunDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate)!
        workouts.append(createWorkout(type: .crossTrain, title: "Active Recovery", dur: 45, date: sunDate, desc: "Bike, Swim, or Hike."))
        
        return workouts
    }
    
    // MARK: - Helpers
    private func createWorkout(type: WorkoutType, title: String, dur: Int, date: Date, dist: Double? = nil, desc: String) -> Workout {
        Workout(
            type: type,
            title: title,
            description: desc,
            date: date,
            durationMinutes: dur,
            distanceKm: dist
        )
    }
    
    private func getVolumeMultiplier(_ level: FitnessLevel) -> Double {
        switch level {
        case .beginner: return 0.7
        case .intermediate: return 1.0
        case .advanced: return 1.4
        }
    }
    
    private func getBaseLongRun(_ dist: Distance) -> Double {
        switch dist {
        case .fiveKm: return 5.0
        case .tenKm: return 6.0
        case .halfMarathon: return 8.0
        case .marathon: return 12.0
        case .ultraTrail: return 15.0
        case .halfIronman: return 40.0 // Combine Bike/Run logic conceptually
        case .ironman: return 60.0
        }
    }
    
    private func getMaxLongRun(_ dist: Distance) -> Double {
        switch dist {
        case .fiveKm: return 10.0
        case .tenKm: return 15.0
        case .halfMarathon: return 22.0
        case .marathon: return 34.0
        case .ultraTrail: return 40.0
        case .halfIronman: return 80.0
        case .ironman: return 120.0
        }
    }
}

// Helper for TimeInterval formatting
extension TimeInterval {
    var formattedPace: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
