import SwiftUI

struct MyEventsView: View {
    @ObservedObject private var dataService = RaceDataService.shared
    
    // Sort events by date (nearest first)
    var sortedEvents: [SavedRaceEntry] {
        dataService.savedEvents.sorted { $0.event.date < $1.event.date }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.themeBackground.edgesIgnoringSafeArea(.all)
                
                if dataService.savedEvents.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(sortedEvents) { entry in
                                if let index = dataService.savedEvents.firstIndex(where: { $0.id == entry.id }) {
                                    NavigationLink(destination: EventStrategyDetailView(entry: $dataService.savedEvents[index])) {
                                        EnhancedEventCard(entry: entry)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Races")
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
                VStack(alignment: .leading, spacing: 16) {
                    Text("Target Configuration").font(.headline)
                    HStack {
                        Text("Target Time:")
                        Spacer()
                        Text(formatDuration(targetTime))
                            .font(.system(.body, design: .monospaced))
                            .bold()
                        Stepper("", value: $targetTime, step: 60).labelsHidden()
                    }
                    VStack(alignment: .leading) {
                        Text("Pace Strategy: \(variationText)")
                            .font(.caption).foregroundColor(.secondary)
                        Slider(value: $variation, in: -5.0...5.0, step: 0.5) {
                            Text("Variation")
                        } minimumValueLabel: { Text("Neg") } maximumValueLabel: { Text("Pos") }
                    }
                    Button(action: recalculate) {
                        Text("Recalculate Plan")
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.themeBlue).foregroundColor(.white).cornerRadius(10)
                    }
                }
                .padding().background(Color.themeCardBackground).cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "drop.fill").foregroundColor(.blue)
                        Text("Nutrition Plan").font(.headline)
                    }
                    ForEach(nutrition) { item in
                        HStack(alignment: .top) {
                            Text(item.formattedTime).font(.caption).bold().frame(width: 50, alignment: .leading)
                            VStack(alignment: .leading) {
                                Text(item.type.rawValue).font(.subheadline).bold()
                                Text(item.description).font(.caption).foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        Divider()
                    }
                }
                .padding().background(Color.themeCardBackground).cornerRadius(12)

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Image(systemName: "stopwatch.fill").foregroundColor(.orange)
                        Text("Kilometer Splits").font(.headline)
                    }.padding()
                    HStack {
                        Text("Km").frame(width: 40)
                        Spacer()
                        Text("Pace").frame(width: 80)
                        Spacer()
                        Text("Elapsed").frame(width: 80)
                    }
                    .font(.caption).foregroundColor(.gray).padding(.horizontal).padding(.bottom, 8)
                    if let splits = strategy?.splits {
                        LazyVStack(spacing: 0) {
                            ForEach(splits) { split in
                                HStack {
                                    Text("\(split.kilometer)").frame(width: 40).font(.system(.body, design: .monospaced))
                                    Spacer()
                                    Text(split.formattedPace).frame(width: 80).font(.system(.body, design: .monospaced))
                                        .foregroundColor(paceColor(for: split, avg: averagePace(splits)))
                                    Spacer()
                                    Text(split.formattedCumulative).frame(width: 80).font(.system(.caption, design: .monospaced)).foregroundColor(.gray)
                                }
                                .padding(.vertical, 8).padding(.horizontal)
                                .background(split.kilometer % 2 == 0 ? Color.gray.opacity(0.05) : Color.clear)
                            }
                        }
                    }
                }
                .background(Color.themeCardBackground).cornerRadius(12)
            }
            .padding()
        }
    }
    
    func recalculate() {
        let distanceKm = getDistanceKm(entry.event.distance)
        strategy = RaceStrategy(
            targetTime: targetTime,
            variation: variation,
            splits: RaceStrategyCalculator.calculateSplits(distanceKm: distanceKm, targetTime: targetTime, variation: variation),
            nutritionPlan: []
        )
        nutrition = RaceStrategyCalculator.generateNutritionPlan(duration: targetTime)
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
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%02d h %02d m", hours, minutes)
    }
    
    func averagePace(_ splits: [RaceSplit]) -> TimeInterval {
        let total = splits.reduce(0) { $0 + $1.time }
        return total / Double(splits.count)
    }
    
    func paceColor(for split: RaceSplit, avg: TimeInterval) -> Color {
        if split.time < avg - 2 { return .green }
        if split.time > avg + 2 { return .red }
        return .primary
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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Progress
                HStack {
                    Text("Ready for Race Day")
                        .font(.headline)
                    Spacer()
                    Text("\(entry.preparation?.checklist.completedCount ?? 0)/\(entry.preparation?.checklist.totalCount ?? 0)")
                        .foregroundColor(.themeGreen)
                }
                .padding()
                .background(Color.themeCardBackground)
                .cornerRadius(12)
                
                if let preparation = entry.preparation {
                    ForEach(ChecklistCategory.allCases, id: \.self) { category in
                        VStack(alignment: .leading, spacing: 12) {
                            Label(category.rawValue, systemImage: category.icon)
                                .font(.headline)
                                .foregroundColor(.themeBlue)
                            
                            ForEach(preparation.checklist.items.indices, id: \.self) { index in
                                if preparation.checklist.items[index].category == category {
                                    ChecklistItemRow(item: Binding(
                                        get: { entry.preparation?.checklist.items[index] ?? preparation.checklist.items[index] },
                                        set: { entry.preparation?.checklist.items[index] = $0 }
                                    ))
                                }
                            }
                        }
                        .padding()
                        .background(Color.themeCardBackground)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
    }
}

struct ChecklistItemRow: View {
    @Binding var item: ChecklistItem
    
    var body: some View {
        Toggle(isOn: $item.isChecked) {
            Text(item.title)
                .font(.body)
                .strikethrough(item.isChecked)
                .foregroundColor(item.isChecked ? .secondary : .primary)
        }
        .toggleStyle(CheckboxToggleStyle())
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(configuration.isOn ? .themeGreen : .gray)
                    .font(.title3)
                configuration.label
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
