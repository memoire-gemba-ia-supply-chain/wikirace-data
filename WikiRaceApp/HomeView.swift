import SwiftUI
import Combine

enum SortOrder: String, CaseIterable {
    case ascending = "Date ↑"
    case descending = "Date ↓"
}

class HomeViewModel: ObservableObject {
    @Published var events: [RaceEvent] = [] {
        didSet {
            filterEvents()
        }
    }
    @Published var filteredEvents: [RaceEvent] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var selectedDiscipline: Discipline? = nil
    @Published var selectedDistance: Distance? = nil
    @Published var searchQuery: String = ""
    @Published var sortOrder: SortOrder = .ascending
    @Published var selectedCountry: String? = nil
    
    // Dynamic Filter Options
    var availableCountries: [String] {
        Set(events.map { $0.country }).sorted()
    }
    
    var availableDisciplines: [Discipline] {
        Array(Set(events.map { $0.discipline })).sorted { $0.rawValue < $1.rawValue }
    }
    
    private let dataService = RaceDataService.shared
    
    init() {
        self.events = dataService.events
        filterEvents()
        
        // Subscribe to changes in dataService
        dataService.$events
            .sink { [weak self] newEvents in
                self?.events = newEvents
            }
            .store(in: &cancellables)
    }
    
    func filterEvents() {
        let today = Date()
        filteredEvents = events.filter { event in
            // Filter Past Events
            if event.date < today {
                return false
            }
            
            // Discipline Filter
            if let discipline = selectedDiscipline, event.discipline != discipline {
                return false
            }
            // Distance Filter
            if let distance = selectedDistance, event.distance != distance {
                return false
            }
            // Country Filter
            if let country = selectedCountry, event.country != country {
                return false
            }
            // Search Query
            if !searchQuery.isEmpty {
                let query = searchQuery.lowercased()
                return event.name.lowercased().contains(query) || 
                       event.city.lowercased().contains(query) || 
                       event.country.lowercased().contains(query)
            }
            
            return true
        }
        
        // Sort by date
        if sortOrder == .ascending {
            filteredEvents.sort { $0.date < $1.date }
        } else {
            filteredEvents.sort { $0.date > $1.date }
        }
    }
    
    func toggleSortOrder() {
        sortOrder = sortOrder == .ascending ? .descending : .ascending
        filterEvents()
    }
    
    func toggleDiscipline(_ discipline: Discipline) {
        if selectedDiscipline == discipline {
            selectedDiscipline = nil
        } else {
            selectedDiscipline = discipline
        }
        filterEvents()
    }
    
    func toggleDistance(_ distance: Distance) {
        if selectedDistance == distance {
            selectedDistance = nil
        } else {
            selectedDistance = distance
        }
        filterEvents()
    }
    
    func toggleCountry(_ country: String) {
        if selectedCountry == country {
            selectedCountry = nil
        } else {
            selectedCountry = country
        }
        filterEvents()
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.themeBackground.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Simplified Header
                    VStack(spacing: 16) {
                        HStack {
                            Text("WikiRace")
                                .font(.largeTitle)
                                .fontWeight(.black)
                                .foregroundColor(.themeTextPrimary)
                            
                            Spacer()
                        }
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search races, cities, countries...", text: $viewModel.searchQuery)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.subheadline)
                                .onChange(of: viewModel.searchQuery) { _ in
                                    viewModel.filterEvents()
                                }
                            
                            if !viewModel.searchQuery.isEmpty {
                                Button(action: {
                                    withAnimation {
                                        viewModel.searchQuery = ""
                                        viewModel.filterEvents()
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.themeCardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.themeBlue.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Sort + Filters
                    HStack {
                        Text("\(viewModel.filteredEvents.count) events")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Button(action: { viewModel.toggleSortOrder() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.arrow.down")
                                Text(viewModel.sortOrder.rawValue)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.themeCardBackground)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Premium Filter Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Active Filter Summary / Clear All
                            if viewModel.selectedDiscipline != nil || viewModel.selectedDistance != nil || viewModel.selectedCountry != nil {
                                Button(action: {
                                    withAnimation(.spring()) {
                                        viewModel.selectedDiscipline = nil
                                        viewModel.selectedDistance = nil
                                        viewModel.selectedCountry = nil
                                        viewModel.filterEvents()
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "xmark.circle.fill")
                                        Text("Clear")
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.themeRed.opacity(0.1))
                                    .foregroundColor(.themeRed)
                                    .cornerRadius(20)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }

                            // Discipline Menu
                            FilterDropdown(
                                title: viewModel.selectedDiscipline?.rawValue ?? "Activity",
                                icon: viewModel.selectedDiscipline?.iconName ?? "figure.run",
                                color: .themeBlue,
                                isSelected: viewModel.selectedDiscipline != nil
                            ) {
                                ForEach(viewModel.availableDisciplines, id: \.self) { discipline in
                                    Button(action: { viewModel.toggleDiscipline(discipline) }) {
                                        Label(discipline.rawValue, systemImage: discipline.iconName)
                                    }
                                }
                            }

                            // Distance Menu
                            FilterDropdown(
                                title: viewModel.selectedDistance?.rawValue ?? "Distance",
                                icon: "ruler",
                                color: .themeOrange,
                                isSelected: viewModel.selectedDistance != nil
                            ) {
                                ForEach(Distance.allCases, id: \.self) { distance in
                                    Button(action: { viewModel.toggleDistance(distance) }) {
                                        Text(distance.rawValue)
                                    }
                                }
                            }

                            // Country Menu
                            FilterDropdown(
                                title: viewModel.selectedCountry ?? "Country",
                                icon: "globe",
                                color: .themeGreen,
                                isSelected: viewModel.selectedCountry != nil
                            ) {
                                ForEach(viewModel.availableCountries, id: \.self) { country in
                                    Button(action: { viewModel.toggleCountry(country) }) {
                                        Text(country)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(Color.themeBackground)
                    .animation(.spring(), value: viewModel.selectedDiscipline)
                    .animation(.spring(), value: viewModel.selectedDistance)
                    .animation(.spring(), value: viewModel.selectedCountry)
                    
                    // Events List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.filteredEvents) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    EventCard(event: event)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
        }
    }
}
// MARK: - Premium Dropdown Component
struct FilterDropdown<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .opacity(0.5)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if isSelected {
                        color.opacity(0.15)
                    } else {
                        Color.themeCardBackground
                    }
                }
            )
            .foregroundColor(isSelected ? color : .themeTextPrimary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color.opacity(0.3) : Color.themeBlue.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: isSelected ? color.opacity(0.3) : Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
    }
}
