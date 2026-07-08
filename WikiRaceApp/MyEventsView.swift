import SwiftUI

struct MyEventsView: View {
    @ObservedObject private var dataService = RaceDataService.shared
    @State private var recordingResultEntry: SavedRaceEntry?
    
    // Sort events by date (nearest first)
    var upcomingEvents: [SavedRaceEntry] {
        dataService.savedEvents.filter { $0.event.date >= Date() && !$0.resultSaved }
            .sorted { $0.event.date < $1.event.date }
    }
    
    var pendingResultEvents: [SavedRaceEntry] {
        dataService.savedEvents.filter { $0.event.date < Date() && !$0.resultSaved }
            .sorted { $0.event.date < $1.event.date }
    }
    
    var completedEvents: [SavedRaceEntry] {
        dataService.savedEvents.filter { $0.resultSaved }
            .sorted { $0.event.date > $1.event.date }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.themeBackground.edgesIgnoringSafeArea(.all)
                
                if dataService.savedEvents.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        if !pendingResultEvents.isEmpty {
                            Section(header: Text(AppStrings.resultNeedsResult).font(.headline).foregroundColor(.themeOrange)) {
                                ForEach(pendingResultEvents) { entry in
                                    PendingResultRow(entry: entry) {
                                        recordingResultEntry = entry
                                    }
                                }
                            }
                        }
                        
                        if !upcomingEvents.isEmpty {
                            Section(header: Text(AppStrings.resultUpcoming).font(.headline).foregroundColor(.themeBlue)) {
                                ForEach(upcomingEvents) { entry in
                                    if let index = dataService.savedEvents.firstIndex(where: { $0.id == entry.id }) {
                                        NavigationLink(destination: EventStrategyDetailView(entry: $dataService.savedEvents[index])) {
                                            EnhancedEventCard(entry: entry)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        
                        if !completedEvents.isEmpty {
                            Section(header: Text(AppStrings.resultHistory).font(.headline).foregroundColor(.themeGreen)) {
                                ForEach(completedEvents) { entry in
                                    CompletedRaceRow(entry: entry)
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle(AppStrings.tabCalendar)
            .sheet(item: $recordingResultEntry) { entry in
                RecordResultView(entry: entry)
            }
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Races Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.gray)
            
            Text("Explore races and add them\nto start your training journey!")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Enhanced Event Card with Progress Ring

struct EnhancedEventCard: View {
    let entry: SavedRaceEntry
    @ObservedObject private var dataService = RaceDataService.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Progress Ring
            ProgressRingView(
                progress: entry.progressPercentage,
                daysRemaining: entry.daysRemaining
            )
            
            // Event Details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.event.flagEmoji)
                    Text(entry.event.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                }
                
                HStack {
                    Text(entry.event.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.gray)
                    Text(entry.event.city)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Distance Badge
                Text(entry.event.distance.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(distanceBadgeColor.opacity(0.2))
                    .foregroundColor(distanceBadgeColor)
                    .cornerRadius(6)
                
                // Motivational Message
                Text(entry.motivationalMessage)
                    .font(.caption2)
                    .foregroundColor(.themeGreen)
                    .padding(.top, 2)
            }
            
            Spacer()
            
            // Remove Button
            Button {
                dataService.removeEvent(entry)
            } label: {
                Image(systemName: "trash.fill")
                    .font(.body)
                    .foregroundColor(.red.opacity(0.7))
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color.themeCardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    var distanceBadgeColor: Color {
        switch entry.event.distance {
        case .fiveKm, .tenKm: return .themeGreen
        case .halfMarathon, .marathon: return .themeBlue
        case .ultraTrail: return .themeOrange
        case .halfIronman, .ironman: return .themeRed
        }
    }
}

// MARK: - Progress Ring

struct ProgressRingView: View {
    let progress: Double
    let daysRemaining: Int
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 6)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.themeGreen, .themeBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Center content
            VStack(spacing: 0) {
                Text("\(daysRemaining)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.themeBlue)
                Text("DAYS")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 70, height: 70)
    }
}

// MARK: - Legacy MyEventCard (kept for compatibility)

struct MyEventCard: View {
    let entry: SavedRaceEntry
    @ObservedObject private var dataService = RaceDataService.shared
    
    var body: some View {
        EnhancedEventCard(entry: entry)
    }
}

// MARK: - Event Strategy Detail View
struct EventStrategyDetailView: View {
    @ObservedObject var dataService = RaceDataService.shared
    @Binding var entry: SavedRaceEntry
    @State private var selectedTab = 1
    @Environment(\.dismiss) var dismiss
    
    // Generic State
    
    // Strategy State
    @State private var targetTimeStr: String = "04:00:00"
    @State private var targetTime: TimeInterval = 14400 // 4h default
    @State private var variation: Double = 0.0 // 0 = Even
    @State private var generatedStrategy: RaceStrategy?
    
    // Nutrition State
    @State private var nutritionPlan: [NutritionItem] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Hero Countdown Header
            VStack(spacing: 8) {
                Text("\(entry.daysRemaining)")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundColor(.themeGreen)
                Text(AppStrings.prepDaysToGo)
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(4)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(Color.themeCardBackground)
            
            // Segmented Control
            Picker("View", selection: $selectedTab) {
                Text(AppStrings.prepStrategy).tag(1)
                Text(AppStrings.prepNutrition).tag(4)
                Text(AppStrings.prepTraining).tag(2)
                Text(AppStrings.prepChecklist).tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Content
            TabView(selection: $selectedTab) {
                
                StrategyView(
                    entry: entry,
                    targetTime: $targetTime,
                    variation: $variation,
                    strategy: $generatedStrategy,
                    nutrition: $nutritionPlan
                )
                .tag(1)
                
                NutritionView(nutrition: nutritionPlan)
                    .tag(4)
                
                TrainingPlanView(entry: $entry)
                    .tag(2)
                
                ChecklistView(entry: $entry)
                    .tag(3)
            }
            #if os(iOS)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            #endif
            
            // Bottom Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    RaceDataService.shared.removeEvent(entry)
                    dismiss()
                }) {
                    Text(AppStrings.prepRemove)
                        .font(.caption)
                        .foregroundColor(.themeRed)
                }
            }
            .padding()
            .background(Color.themeCardBackground.edgesIgnoringSafeArea(.bottom))
        }
        .navigationTitle(entry.event.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            initializeStrategy()
        }
        .onDisappear {
            dataService.save()
        }
    }
    
    func initializeStrategy() {
        if entry.strategy != nil {
            // persistence TODO
        } else {
            switch entry.event.distance {
            case .marathon: targetTime = 14400
            case .halfMarathon: targetTime = 7200
            case .tenKm: targetTime = 3600
            case .fiveKm: targetTime = 1800
            case .ultraTrail: targetTime = 36000
            default: targetTime = 7200
            }
            calculate()
            if entry.preparation == nil {
                entry.preparation = RacePreparation()
            }
            generateTrainingPlan()
        }
    }
    
    func generateTrainingPlan() {
        if entry.preparation?.trainingPlan == nil {
            let distance = entry.event.distance
            
            // Generate using the new service
            entry.preparation?.trainingPlan = TrainingPlanGenerator.shared.generate(
                raceEvent: entry.event,
                fitnessLevel: entry.preparation?.fitnessLevel ?? .intermediate,
                goalPace: nil // Could be derived from targetTime
            )
        }
    }
    
    func getDistanceKm(_ dist: Distance) -> Double {
        switch dist {
        case .fiveKm: return 5.0
        case .tenKm: return 10.0
        case .halfMarathon: return 21.1
        case .marathon: return 42.2
        case .halfIronman: return 21.1
        case .ironman: return 42.2
        case .ultraTrail: return 50.0
        }
    }
    
    func calculate() {
        let distanceKm = getDistanceKm(entry.event.distance)
        generatedStrategy = RaceStrategy(
            targetTime: targetTime,
            variation: variation,
            splits: RaceStrategyCalculator.calculateSplits(distanceKm: distanceKm, targetTime: targetTime, variation: variation),
            nutritionPlan: []
        )
        nutritionPlan = RaceStrategyCalculator.generateNutritionPlan(duration: targetTime)
    }
}

// MARK: - Strategy Subview
struct StrategyView: View {
    let entry: SavedRaceEntry
    @Binding var targetTime: TimeInterval
    @Binding var variation: Double
    @Binding var strategy: RaceStrategy?
    @Binding var nutrition: [NutritionItem]
    
    var distanceKm: Double {
        switch entry.event.distance {
        case .fiveKm: return 5.0
        case .tenKm: return 10.0
        case .halfMarathon: return 21.1
        case .marathon: return 42.2
        case .halfIronman: return 21.1
        case .ironman: return 42.2
        case .ultraTrail: return 50.0
        }
    }
    
    var averagePace: TimeInterval {
        targetTime / distanceKm
    }
    
    var variationText: String {
        if variation < -1.0 { return "Strong Negative Split" }
        if variation < 0.0 { return "Negative Split" }
        if variation == 0.0 { return "Even Splits" }
        if variation > 1.0 { return "Positive Split (Aggressive)" }
        return "Positive Split"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Performance Hero Dashboard
                VStack(spacing: 12) {
                    // Top Hero: Target Time
                    VStack(spacing: 8) {
                        Text("TARGET FINISH")
                            .font(.system(size: 10, weight: .black))
                            .opacity(0.7)
                        Text(formatDuration(targetTime))
                            .font(.system(size: 44, weight: .black, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [.themeBlue, .themeBlue.opacity(0.9)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(24)
                    .shadow(color: Color.themeBlue.opacity(0.3), radius: 10, x: 0, y: 8)

                    // Bottom Row: Distance & Avg Pace
                    HStack(spacing: 12) {
                        MetricCard(label: "DISTANCE", value: String(format: "%.1f", distanceKm), unit: "km", icon: "figure.run")
                        MetricCard(label: "AVG PACE", value: formatPace(averagePace), unit: "/km", icon: "timer")
                    }
                }
                
                // Configuration Card
                VStack(alignment: .leading, spacing: 20) {
                    Text("Strategy Configuration")
                        .font(.headline)
                        .foregroundColor(.themeTextPrimary)
                    
                    VStack(spacing: 24) {
                        // Time Selection
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Final Time", systemImage: "timer")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Spacer()
                                Text(formatDuration(targetTime))
                                    .font(.system(.title3, design: .monospaced))
                                    .fontWeight(.black)
                                    .foregroundColor(.themeBlue)
                            }
                            Stepper("", value: $targetTime, in: 600...86400, step: 60)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        
                        Divider()
                        
                        // Pace Strategy
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Pace Strategy", systemImage: "chart.bar.xaxis")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Spacer()
                                Text(variationText)
                                    .font(.caption)
                                    .fontWeight(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(variation < 0 ? Color.themeGreen.opacity(0.1) : Color.themeRed.opacity(0.1))
                                    .foregroundColor(variation < 0 ? .themeGreen : .themeRed)
                                    .cornerRadius(6)
                            }
                            
                            Slider(value: $variation, in: -5.0...5.0, step: 0.5)
                                .accentColor(.themeBlue)
                            
                            HStack {
                                Text("Negative Split").font(.caption2).foregroundColor(.secondary)
                                Spacer()
                                Text("Positive Split").font(.caption2).foregroundColor(.secondary)
                            }
                            
                            // Visual Pace Chart (Mini)
                            if let splits = strategy?.splits {
                                PaceVariationMiniChart(splits: splits, avg: averagePace)
                                    .frame(height: 40)
                                    .padding(.top, 8)
                            }
                        }
                    }
                    
                    Button(action: recalculate) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Update Strategy")
                        }
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.themeBlue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(Color.themeCardBackground)
                .cornerRadius(20)
                
                // Splits Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "stopwatch.fill").foregroundColor(.orange)
                        Text("Kilometer Splits").font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("KM").frame(width: 40, alignment: .leading)
                            Spacer()
                            Text("PACE").frame(width: 80, alignment: .center)
                            Spacer()
                            Text("ELAPSED").frame(width: 90, alignment: .trailing)
                        }
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                        
                        if let splits = strategy?.splits {
                            VStack(spacing: 0) {
                                ForEach(splits) { split in
                                    let isMilestone = split.kilometer % 5 == 0 || split.kilometer == 1 || split.kilometer == Int(ceil(distanceKm))
                                    
                                    HStack {
                                        Text("\(split.kilometer)")
                                            .font(.system(.subheadline, design: .monospaced))
                                            .fontWeight(isMilestone ? .black : .medium)
                                            .frame(width: 40, alignment: .leading)
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 4) {
                                            Circle()
                                                .fill(paceColor(for: split, avg: averagePace))
                                                .frame(width: 6, height: 6)
                                            Text(split.formattedPace)
                                                .font(.system(.subheadline, design: .monospaced))
                                                .fontWeight(.bold)
                                        }
                                        .frame(width: 80, alignment: .center)
                                        
                                        Spacer()
                                        
                                        Text(split.formattedCumulative)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                            .frame(width: 90, alignment: .trailing)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal)
                                    .background(isMilestone ? Color.themeBlue.opacity(0.05) : Color.clear)
                                    
                                    if split.id != splits.last?.id {
                                        Divider().padding(.leading, 12)
                                    }
                                }
                            }
                        }
                    }
                    .background(Color.themeCardBackground)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
                }
            }
            .padding()
        }
    }
    
    func recalculate() {
        let currentDist = distanceKm
        strategy = RaceStrategy(
            targetTime: targetTime,
            variation: variation,
            splits: RaceStrategyCalculator.calculateSplits(distanceKm: currentDist, targetTime: targetTime, variation: variation),
            nutritionPlan: []
        )
        nutrition = RaceStrategyCalculator.generateNutritionPlan(duration: targetTime)
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    func formatPace(_ pace: TimeInterval) -> String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func paceColor(for split: RaceSplit, avg: TimeInterval) -> Color {
        let diff = split.time - avg
        if diff < -2 { return .themeGreen }
        if diff > 2 { return .themeRed }
        return .orange
    }
}

struct MetricCard: View {
    let label: String
    let value: String
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.themeBlue)
                Text(label)
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(.themeTextPrimary)
                Text(unit)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.themeCardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

struct PaceVariationMiniChart: View {
    let splits: [RaceSplit]
    let avg: TimeInterval
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(splits) { split in
                let diff = avg - split.time // positive means faster than avg
                let normalizedHeight = 20 + (diff * 2) // scale for visual
                
                RoundedRectangle(cornerRadius: 1)
                    .fill(diff > 0 ? Color.themeGreen : Color.themeRed)
                    .frame(height: max(5, min(40, CGFloat(normalizedHeight))))
            }
        }
    }
}

// MARK: - Nutrition View
struct NutritionView: View {
    let nutrition: [NutritionItem]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "drop.fill").foregroundColor(.blue)
                        Text("Nutrition & Hydration Strategy")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Text("Fueling is as important as training. Follow this schedule to maintain energy levels throughout your race.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.themeCardBackground)
                .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(nutrition) { item in
                        VStack(spacing: 0) {
                            HStack(alignment: .top, spacing: 16) {
                                Text(item.formattedTime)
                                    .font(.system(.headline, design: .monospaced))
                                    .foregroundColor(.themeBlue)
                                    .frame(width: 60, alignment: .leading)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(item.type.rawValue)
                                            .font(.headline)
                                        Spacer()
                                        Image(systemName: nutritionIcon(for: item.type))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(item.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            
                            if item.id != nutrition.last?.id {
                                Divider().padding(.leading, 76)
                            }
                        }
                    }
                }
                .background(Color.themeCardBackground)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            }
            .padding()
        }
    }
    
    func nutritionIcon(for type: NutritionItem.NutritionType) -> String {
        switch type {
        case .water: return "drop.fill"
        case .gel: return "bolt.fill"
        case .salt: return "pill.fill"
        case .food: return "leaf.fill"
        case .caffeine: return "cup.and.saucer.fill"
        }
    }
}

// MARK: - Training Plan View
struct TrainingPlanView: View {
    @Binding var entry: SavedRaceEntry
    @State private var selectedWeek: Int = 1
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let plan = entry.preparation?.trainingPlan {
                    // Overall Progress
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Overall Progress").font(.headline)
                                Text("\(Int(plan.overallProgress * 100))% of workouts completed").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            ZStack {
                                Circle().stroke(Color.gray.opacity(0.2), lineWidth: 8)
                                Circle().trim(from: 0, to: plan.overallProgress).stroke(Color.themeBlue, style: StrokeStyle(lineWidth: 8, lineCap: .round)).rotationEffect(.degrees(-90))
                                Text("\(Int(plan.overallProgress * 100))%").font(.caption2).bold()
                            }.frame(width: 50, height: 50)
                        }
                    }
                    .padding()
                    .background(Color.themeCardBackground)
                    .cornerRadius(12)
                    
                    // Week Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Program Schedule").font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(plan.weeks) { week in
                                    Button(action: { selectedWeek = week.weekNumber }) {
                                        VStack {
                                            Text("W\(week.weekNumber)").font(.caption).bold()
                                            Text(week.focus).font(.system(size: 8))
                                        }
                                        .frame(width: 50, height: 45)
                                        .background(selectedWeek == week.weekNumber ? Color.themeBlue : Color.gray.opacity(0.1))
                                        .foregroundColor(selectedWeek == week.weekNumber ? .white : .primary)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.themeCardBackground)
                    .cornerRadius(12)
                    
                    // Workouts for Selected Week
                    if let week = plan.weeks.first(where: { $0.weekNumber == selectedWeek }) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Week \(week.weekNumber): \(week.focus) Phase")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("\(week.completedCount)/\(week.totalWorkouts) done").font(.caption).foregroundColor(.secondary)
                            }
                            
                            if let weekIndex = plan.weeks.firstIndex(where: { $0.id == week.id }) {
                                ForEach(entry.preparation?.trainingPlan?.weeks[weekIndex].workouts.indices ?? 0..<0, id: \.self) { workoutIndex in
                                    WorkoutRow(
                                        workout: Binding(
                                            get: { entry.preparation?.trainingPlan?.weeks[weekIndex].workouts[workoutIndex] ?? week.workouts[workoutIndex] },
                                            set: { entry.preparation?.trainingPlan?.weeks[weekIndex].workouts[workoutIndex] = $0 }
                                        ),
                                        onToggle: { /* Persistence handled by Binding */ }
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "timer")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Generating your plan...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                }
            }
            .padding()
        }
        .onAppear {
            if let current = entry.preparation?.trainingPlan?.currentWeekIndex {
                selectedWeek = current + 1
            }
        }
    }
}

struct WorkoutRow: View {
    @Binding var workout: Workout
    var onToggle: () -> Void
    
    var body: some View {
        Button(action: {
            workout.isCompleted.toggle()
            onToggle()
        }) {
            HStack(spacing: 16) {
                Image(systemName: workout.isCompleted ? "checkmark.circle.fill" : workout.type.icon)
                    .font(.title2)
                    .foregroundColor(workout.isCompleted ? .themeGreen : (workout.type.color == "themeBlue" ? .themeBlue : .themeGreen))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.title)
                        .font(.headline)
                        .strikethrough(workout.isCompleted)
                        .foregroundColor(workout.isCompleted ? .secondary : .primary)
                    Text(workout.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(workout.formattedDuration)
                        .font(.caption)
                        .bold()
                    Text(workout.formattedDistance)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.themeCardBackground)
            .cornerRadius(10)
            .opacity(workout.isCompleted ? 0.8 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Checklist View
struct ChecklistView: View {
    @Binding var entry: SavedRaceEntry
    
    var progress: Double {
        let total = entry.preparation?.checklist.totalCount ?? 0
        let completed = entry.preparation?.checklist.completedCount ?? 0
        return total > 0 ? Double(completed) / Double(total) : 0
    }
    
    var statusMessage: String {
        if progress == 1.0 { return "You're all set! 🚀" }
        if progress > 0.7 { return "Almost ready!" }
        if progress > 0.3 { return "Making progress..." }
        return "Gear up!"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Status Card Header
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(statusMessage)
                                .font(.title3)
                                .fontWeight(.black)
                            Text("\(Int(progress * 100))% complete")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: progress == 1.0 ? "checkmark.seal.fill" : "list.bullet.clipboard")
                            .font(.system(size: 40))
                            .foregroundColor(progress == 1.0 ? .themeGreen : .themeBlue)
                    }
                    
                    ProgressView(value: progress)
                        .accentColor(progress == 1.0 ? .themeGreen : .themeBlue)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                .padding()
                .background(Color.themeCardBackground)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                
                if let preparation = entry.preparation {
                    ForEach(ChecklistCategory.allCases, id: \.self) { category in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: category.icon)
                                    .font(.headline)
                                Text(category.rawValue)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            .foregroundColor(categoryColor(category))
                            .padding(.bottom, 4)
                            
                            VStack(spacing: 1) {
                                ForEach(preparation.checklist.items.indices, id: \.self) { index in
                                    if preparation.checklist.items[index].category == category {
                                        ChecklistItemRow(item: Binding(
                                            get: { entry.preparation?.checklist.items[index] ?? preparation.checklist.items[index] },
                                            set: { entry.preparation?.checklist.items[index] = $0 }
                                        ), accentColor: categoryColor(category))
                                        
                                        if index != preparation.checklist.items.count - 1 {
                                            Divider().padding(.leading, 44)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.themeCardBackground)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(categoryColor(category).opacity(0.1), lineWidth: 1)
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    func categoryColor(_ category: ChecklistCategory) -> Color {
        switch category {
        case .gear: return .themeBlue
        case .nutrition: return .themeGreen
        case .travel: return .themeOrange
        case .pacing: return .themeRed
        }
    }
}

struct ChecklistItemRow: View {
    @Binding var item: ChecklistItem
    var accentColor: Color
    
    var body: some View {
        Toggle(isOn: $item.isChecked) {
            Text(item.title)
                .font(.body)
                .fontWeight(item.isChecked ? .medium : .bold)
                .foregroundColor(item.isChecked ? .secondary : .themeTextPrimary)
                .strikethrough(item.isChecked)
        }
        .toggleStyle(CheckboxToggleStyle(accentColor: accentColor))
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                item.isChecked.toggle()
            }
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    var accentColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            ZStack {
                Circle()
                    .stroke(configuration.isOn ? accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                if configuration.isOn {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(accentColor)
                        .font(.system(size: 24))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.trailing, 8)
            
            configuration.label
            Spacer()
        }
    }
}

// MARK: - Result Related Views

struct PendingResultRow: View {
    let entry: SavedRaceEntry
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.themeOrange.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "timer")
                        .foregroundColor(.themeOrange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.event.name)
                        .font(.headline)
                        .foregroundColor(.themeTextPrimary)
                    Text("Did you finish this race?")
                        .font(.subheadline)
                        .foregroundColor(.themeOrange)
                }
                
                Spacer()
                
                Image(systemName: "pencil.circle.fill")
                    .font(.title)
                    .foregroundColor(.themeOrange)
            }
            .padding(.vertical, 8)
        }
    }
}

struct CompletedRaceRow: View {
    let entry: SavedRaceEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Achievement Icon
            ZStack {
                Circle()
                    .fill(entry.isFinished == true ? Color.themeGreen.opacity(0.1) : Color.themeRed.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: entry.isFinished == true ? "medal.fill" : "xmark.seal.fill")
                    .foregroundColor(entry.isFinished == true ? .themeGreen : .themeRed)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.event.name)
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)
                
                HStack {
                    if entry.isFinished == true {
                        Text("Finished")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.themeGreen.opacity(0.2))
                            .foregroundColor(.themeGreen)
                            .cornerRadius(4)
                        
                        if let time = entry.actualTime {
                            Text(formatDuration(time))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("DNF / DNS")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.themeRed.opacity(0.2))
                            .foregroundColor(.themeRed)
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            Text(entry.event.formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDuration(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct RecordResultView: View {
    let entry: SavedRaceEntry
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var dataService = RaceDataService.shared
    
    @State private var isFinished: Bool = true
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("RACE COMPLETION")) {
                    Picker("Did you finish?", selection: $isFinished) {
                        Text("Yes! 🏁").tag(true)
                        Text("No ❌").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical, 8)
                }
                
                if isFinished {
                    Section(header: Text("YOUR FINISH TIME")) {
                        HStack {
                            VStack {
                                Text("HR")
                                    .font(.caption2)
                                Picker("Hours", selection: $hours) {
                                    ForEach(0..<24) { i in
                                        Text("\(i)").tag(i)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60, height: 100)
                                .clipped()
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("MIN")
                                    .font(.caption2)
                                Picker("Minutes", selection: $minutes) {
                                    ForEach(0..<60) { i in
                                        Text("\(i)").tag(i)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60, height: 100)
                                .clipped()
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("SEC")
                                    .font(.caption2)
                                Picker("Seconds", selection: $seconds) {
                                    ForEach(0..<60) { i in
                                        Text("\(i)").tag(i)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60, height: 100)
                                .clipped()
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        let totalSeconds = TimeInterval(hours * 3600 + minutes * 60 + seconds)
                        dataService.saveResult(for: entry.id, isFinished: isFinished, actualTime: isFinished ? totalSeconds : nil)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Save Result")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.themeBlue)
                            .cornerRadius(12)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            .navigationTitle("Race Result")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
