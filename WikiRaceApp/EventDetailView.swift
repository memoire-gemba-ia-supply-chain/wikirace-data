import SwiftUI
import EventKit

struct EventDetailView: View {
    let event: RaceEvent
    @State private var showingAddSheet = false
    @State private var showingConfirmation = false
    @State private var savedEntry: SavedRaceEntry?
    @State private var navigateToPreparation = false
    @ObservedObject private var dataService = RaceDataService.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Image
                ZStack(alignment: .bottomLeading) {
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .background(Color.gray.opacity(0.3))
                        .clipped()
                    
                    LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.discipline.rawValue.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.themeGreen)
                        
                        Text(event.name)
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text(event.flagEmoji)
                            Text("\(event.city), \(event.country)")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    // Key Info
                    HStack(spacing: 20) {
                        InfoBadge(icon: "ruler", value: event.distance.rawValue, label: "Distance")
                        if event.price != nil {
                            InfoBadge(icon: "banknote", value: event.formattedPrice, label: "Price")
                        }
                        InfoBadge(icon: "calendar", value: event.formattedDate, label: "Date")
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About the Event")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(event.description)
                            .font(.body)
                            .foregroundColor(.themeTextSecondary)
                            .lineSpacing(4)
                    }
                    
                    // Actions
                    VStack(spacing: 16) {
                        // Only show registration link if URL looks valid
                        if event.registrationUrl.absoluteString != "https://example.com" {
                            Link(destination: event.registrationUrl) {
                                HStack {
                                    Text("Register Now")
                                        .fontWeight(.bold)
                                    Image(systemName: "arrow.up.right")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.themeBlue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        
                        // Show different button based on saved status
                        if let index = dataService.savedEvents.firstIndex(where: { $0.event.id == event.id }) {
                            NavigationLink(destination: EventStrategyDetailView(entry: $dataService.savedEvents[index])) {
                                HStack {
                                    Text("View My Preparation")
                                        .fontWeight(.bold)
                                    Image(systemName: "arrow.right.circle.fill")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.themeGreen)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        } else {
                            Button {
                                showingAddSheet = true
                            } label: {
                                HStack {
                                    Text("Add to My Calendar")
                                        .fontWeight(.medium)
                                    Image(systemName: "calendar.badge.plus")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.themeCardBackground)
                                .foregroundColor(.themeTextPrimary)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .edgesIgnoringSafeArea(.top)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showingAddSheet) {
            AddToCalendarSheet(event: event, showingConfirmation: $showingConfirmation, onSave: { entry in
                savedEntry = entry
            })
        }
        .alert("Added!", isPresented: $showingConfirmation) {
            Button("Start Training Plan") {
                navigateToPreparation = true
            }
            Button("Later", role: .cancel) { }
        } message: {
            Text("Event added to your calendar! Start your training plan now?")
        }
        .navigationDestination(isPresented: $navigateToPreparation) {
            if let entry = savedEntry, let index = dataService.savedEvents.firstIndex(where: { $0.id == entry.id }) {
                EventStrategyDetailView(entry: $dataService.savedEvents[index])
            }
        }
    }
}

// MARK: - Add to Calendar Sheet with Goal Input
struct AddToCalendarSheet: View {
    let event: RaceEvent
    @Binding var showingConfirmation: Bool
    var onSave: ((SavedRaceEntry) -> Void)? = nil
    @Environment(\.dismiss) var dismiss
    
    @State private var goalType: GoalType = .pace
    @State private var paceMinutes: String = "5"
    @State private var paceSeconds: String = "00"
    @State private var speedKmh: String = "12"
    @State private var notes: String = ""
    
    enum GoalType: String, CaseIterable {
        case pace = "Pace (min/km)"
        case speed = "Speed (km/h)"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Choose Goal Type")) {
                    Picker("Goal Type", selection: $goalType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Set Your Target")) {
                    if goalType == .pace {
                        HStack {
                            TextField("Min", text: $paceMinutes)
                            #if os(iOS)
                                .keyboardType(.numberPad)
                            #endif
                                .frame(width: 50)
                            Text(":")
                            TextField("Sec", text: $paceSeconds)
                            #if os(iOS)
                                .keyboardType(.numberPad)
                            #endif
                                .frame(width: 50)
                            Text("min/km")
                                .foregroundColor(.gray)
                        }
                    } else {
                        HStack {
                            TextField("Speed", text: $speedKmh)
                            #if os(iOS)
                                .keyboardType(.decimalPad)
                            #endif
                                .frame(width: 80)
                            Text("km/h")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("Notes (Optional)")) {
                    TextField("E.g., race strategy, hydration plan...", text: $notes)
                }
                
                Section {
                    Button {
                        saveToCalendar()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Add to My Calendar")
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Set Your Goal")
            #if os(iOS)
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
            #endif
        }
    }
    
    func saveToCalendar() {
        // 1. Save locally (existing logic)
        let pace: String? = goalType == .pace ? "\(paceMinutes):\(paceSeconds)" : nil
        let speed: Double? = goalType == .speed ? Double(speedKmh) : nil
        
        let savedEntry = RaceDataService.shared.saveEvent(event, pace: pace, speed: speed, notes: notes.isEmpty ? nil : notes)
        
        // Notify parent view of saved entry
        if let entry = savedEntry {
            onSave?(entry)
        }
        
        // 2. Save to System Calendar
        #if os(iOS)
        let eventStore = EKEventStore()
        
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                if granted, error == nil {
                    DispatchQueue.main.async {
                        addEventToSystemCalendar(store: eventStore)
                    }
                } else {
                    print("Access denied or error: \(String(describing: error))")
                }
            }
        } else {
            // Fallback for older iOS versions
            eventStore.requestAccess(to: .event) { granted, error in
                if granted, error == nil {
                     DispatchQueue.main.async {
                        addEventToSystemCalendar(store: eventStore)
                    }
                }
            }
        }
        #endif
        
        dismiss()
        showingConfirmation = true
    }

    func addEventToSystemCalendar(store: EKEventStore) {
        let calendarEvent = EKEvent(eventStore: store)
        calendarEvent.title = event.name
        calendarEvent.startDate = event.date
        calendarEvent.endDate = event.date.addingTimeInterval(3600 * 4) // Default 4 hours
        calendarEvent.notes = "Race: \(event.name)\nCity: \(event.city)\nDist: \(event.distance.rawValue)\nNotes: \(notes)"
        calendarEvent.calendar = store.defaultCalendarForNewEvents
        
        do {
            try store.save(calendarEvent, span: .thisEvent)
            print("Saved to system calendar")
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
}

struct InfoBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.themeOrange)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
