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
    
    // Mock countries for filter
    let availableCountries = ["France", "Germany", "USA", "UK", "Spain", "Switzerland"]
    @Published var selectedCountry: String? = nil
    
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
                    // Header / Search Log
                    HStack {
                        Text("WikiRace")
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .foregroundColor(.themeTextPrimary)
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.themeBlue)
                            .padding(10)
                            .background(Color.themeCardBackground)
                            .clipShape(Circle())
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
                    
                    // Filters ScrollView
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 12) {
                            
                            // Disciplines
                            HStack(spacing: 12) {
                                ForEach(Discipline.allCases, id: \.self) { discipline in
                                    FilterButton(
                                        title: discipline.rawValue,
                                        iconName: discipline.iconName,
                                        isSelected: viewModel.selectedDiscipline == discipline
                                    ) {
                                        viewModel.toggleDiscipline(discipline)
                                    }
                                }
                            }
                            
                            // Distances
                            HStack(spacing: 12) {
                                ForEach(Distance.allCases, id: \.self) { distance in
                                    FilterButton(
                                        title: distance.rawValue,
                                        iconName: nil,
                                        isSelected: viewModel.selectedDistance == distance
                                    ) {
                                        viewModel.toggleDistance(distance)
                                    }
                                }
                            }
                            
                            // Countries (Simplified)
                            HStack(spacing: 12) {
                                ForEach(viewModel.availableCountries, id: \.self) { country in
                                    FilterButton(
                                        title: country,
                                        iconName: "flag",
                                        isSelected: viewModel.selectedCountry == country
                                    ) {
                                        viewModel.toggleCountry(country)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    
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
