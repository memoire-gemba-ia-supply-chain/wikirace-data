import Foundation

class RaceDataService: ObservableObject {
    static let shared = RaceDataService() // Singleton
    
    @Published var events: [RaceEvent] = []
    @Published var savedEvents: [SavedRaceEntry] = [] {
        didSet {
            save()
        }
    }
    
    @Published var userProfile: UserProfile = .empty {
        didSet {
            save()
        }
    }
    
    @Published var isLoading: Bool = false
    @Published var lastUpdate: Date?
    
    // URL to hosted events.json
    private let remoteURL = "https://raw.githubusercontent.com/memoire-gemba-ia-supply-chain/wikirace-data/main/events.json"
    private let saveKey = "saved_races_v1"
    private let profileKey = "user_profile_v1"
    
    private init() {
        // Start with empty, then load local bundled data
        self.events = []
        load()
        loadBundledEvents()
        Task { await fetchRemoteEvents() }
    }
    
    // MARK: - Load Bundled Events
    
    private func loadBundledEvents() {
        guard let url = Bundle.main.url(forResource: "events", withExtension: "json") else {
            print("⚠️ No bundled events.json found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let response = try JSONDecoder().decode(RemoteEventsWrapper.self, from: data)
            
            let today = Calendar.current.startOfDay(for: Date())
            let futureEvents = response.events
                .map { $0.toRaceEvent() }
                .filter { $0.date >= today }
                .sorted { $0.date < $1.date }
            
            self.events = futureEvents
            print("📦 Loaded \(futureEvents.count) events from bundle")
        } catch {
            print("❌ Failed to load bundled events: \(error)")
        }
    }
    
    // MARK: - Persistence
    
    func save() {
        let encoder = JSONEncoder()
        
        // Save Events
        if let encoded = try? encoder.encode(savedEvents) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
        
        // Save Profile
        if let encoded = try? encoder.encode(userProfile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }
    
    func load() {
        let decoder = JSONDecoder()
        
        // Load Events
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            if let decoded = try? decoder.decode([SavedRaceEntry].self, from: data) {
                self.savedEvents = decoded
                print("📂 Loaded \(self.savedEvents.count) saved events")
            }
        }
        
        // Load Profile
        if let data = UserDefaults.standard.data(forKey: profileKey) {
            if let decoded = try? decoder.decode(UserProfile.self, from: data) {
                self.userProfile = decoded
                print("📂 Loaded user profile with \(decoded.healthLogs.count) logs")
            }
        }
    }
    
    func saveResult(for entryId: UUID, isFinished: Bool, actualTime: TimeInterval?) {
        if let index = savedEvents.firstIndex(where: { $0.id == entryId }) {
            savedEvents[index].isFinished = isFinished
            savedEvents[index].actualTime = actualTime
            savedEvents[index].resultSaved = true
            save()
        }
    }
    
    @Published var lastFetchLog: String = ""
    
    @MainActor
    func fetchRemoteEvents() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: remoteURL) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            
            var remoteEvents: [RaceEvent] = []
            var lastUpdatedStr = "Unknown"
            
            // Try new format with wrapper first
            if let wrapper = try? decoder.decode(RemoteEventsWrapper.self, from: data) {
                remoteEvents = wrapper.events.map { $0.toRaceEvent() }
                lastUpdatedStr = wrapper.lastUpdated
            } else {
                // Fallback to old array format
                let rawEvents = try decoder.decode([RemoteRaceEvent].self, from: data)
                remoteEvents = rawEvents.map { $0.toRaceEvent() }
            }
            
            // 1. Filter Past Events
            let today = Date()
            let upcomingEvents = remoteEvents.filter { $0.date >= today }
            let pastEventsCount = remoteEvents.count - upcomingEvents.count
            
            // 2. Merge Logic
            var newCount = 0
            var updatedCount = 0
            
            // Create a dictionary for faster lookup of existing events by ID (if stable) or Name+Date
            // Assuming IDs are stable for now, otherwise we'd match on Name
            
            for remoteEvent in upcomingEvents {
                if let index = self.events.firstIndex(where: { $0.name == remoteEvent.name && Calendar.current.isDate($0.date, inSameDayAs: remoteEvent.date) }) {
                    // Update existing (preserve ID if needed, but here we just update mutable fields)
                    // In a real app complexity we might check if fields actually changed
                    self.events[index].price = remoteEvent.price
                    self.events[index].registrationStatus = remoteEvent.registrationStatus
                    self.events[index].description = remoteEvent.description
                    updatedCount += 1
                } else {
                    // Add new
                    self.events.append(remoteEvent)
                    newCount += 1
                }
            }
            
            // 3. Cleanup local events that might have passed since last launch
            self.events = self.events.filter { $0.date >= today }
            
            // 4. Sort
            self.events.sort { $0.date < $1.date }
            
            self.lastUpdate = Date()
            self.lastFetchLog = """
            ✅ Fetch Success at \(Date().formatted(date: .omitted, time: .standard))
            Remote: \(remoteEvents.count) total (Updated: \(lastUpdatedStr))
            Filtered Past: \(pastEventsCount)
            New Added: \(newCount) | Updated: \(updatedCount)
            Total Active: \(self.events.count)
            """
            print(self.lastFetchLog)
            
        } catch {
            self.lastFetchLog = "⚠️ Fetch Failed: \(error.localizedDescription)"
            print(self.lastFetchLog)
        }
    }
    
    @discardableResult
    func saveEvent(_ event: RaceEvent, pace: String?, speed: Double?, notes: String?) -> SavedRaceEntry? {
        // Prevent duplicates
        if let existing = savedEvents.first(where: { $0.event.id == event.id }) {
            return existing
        }
        let entry = SavedRaceEntry(event: event, targetPace: pace, targetSpeed: speed, notes: notes)
        savedEvents.append(entry)
        return entry
    }
    
    func removeEvent(_ entry: SavedRaceEntry) {
        savedEvents.removeAll { $0.id == entry.id }
    }
    
    private func generateMockData() -> [RaceEvent] {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            RaceEvent(
                id: UUID(),
                name: "Paris Marathon",
                date: calendar.date(byAdding: .month, value: 2, to: today)!,
                city: "Paris",
                country: "France",
                countryCode: "FR",
                discipline: .running,
                distance: .marathon,
                elevationGain: 150,
                description: "One of the biggest marathons in the world, offering a unique opportunity to make the city yours by participating in one of the most coveted races on the globe.",
                registrationUrl: URL(string: "https://www.schneiderelectricparismarathon.com")!,
                imageUrl: "paris_marathon_img",
                price: 110,
                currency: "EUR",
                registrationStatus: .open
            ),
            RaceEvent(
                id: UUID(),
                name: "UTMB Mont-Blanc",
                date: calendar.date(byAdding: .month, value: 6, to: today)!,
                city: "Chamonix",
                country: "France",
                countryCode: "FR",
                discipline: .trail,
                distance: .ultraTrail,
                elevationGain: 10000,
                description: "The summit of trail running. A mythical race around Mont Blanc.",
                registrationUrl: URL(string: "https://montblanc.utmb.world")!,
                imageUrl: "utmb_img",
                price: 350,
                currency: "EUR",
                registrationStatus: .soldOut
            ),
            RaceEvent(
                id: UUID(),
                name: "Berlin Marathon",
                date: calendar.date(byAdding: .month, value: 7, to: today)!,
                city: "Berlin",
                country: "Germany",
                countryCode: "DE",
                discipline: .running,
                distance: .marathon,
                elevationGain: 20,
                description: "The fastest marathon course in the world. Perfect for setting a PB.",
                registrationUrl: URL(string: "https://www.bmw-berlin-marathon.com")!,
                imageUrl: "berlin_marathon_img",
                price: 160,
                currency: "EUR",
                registrationStatus: .closed
            ),
            RaceEvent(
                id: UUID(),
                name: "Ironman Hawaii",
                date: calendar.date(byAdding: .month, value: 8, to: today)!,
                city: "Kailua-Kona",
                country: "USA",
                countryCode: "US",
                discipline: .triathlon,
                distance: .ironman,
                elevationGain: 1200,
                description: "The Ironman World Championship. The ultimate test of body, mind and spirit.",
                registrationUrl: URL(string: "https://www.ironman.com/im-world-championship")!,
                imageUrl: "ironman_kona_img",
                price: 850,
                currency: "USD",
                registrationStatus: .open
            ),
            RaceEvent(
                id: UUID(),
                name: "London 10K",
                date: calendar.date(byAdding: .month, value: 1, to: today)!,
                city: "London",
                country: "UK",
                countryCode: "GB",
                discipline: .running,
                distance: .tenKm,
                elevationGain: 40,
                description: "Run through the heart of London past its most famous landmarks.",
                registrationUrl: URL(string: "https://www.london10k.com")!,
                imageUrl: "london_10k_img",
                price: 45,
                currency: "GBP",
                registrationStatus: .open
            ),
             RaceEvent(
                id: UUID(),
                name: "Zermatt Ultra",
                date: calendar.date(byAdding: .month, value: 5, to: today)!,
                city: "Zermatt",
                country: "Switzerland",
                countryCode: "CH",
                discipline: .trail,
                distance: .ultraTrail,
                elevationGain: 3000,
                description: "A challenging ultra trail at the foot of the Matterhorn.",
                registrationUrl: URL(string: "https://www.zermatt-marathon.com")!,
                imageUrl: "zermatt_img",
                price: 120,
                currency: "CHF",
                registrationStatus: .open
            ),
             RaceEvent(
                 id: UUID(),
                 name: "Valencia Half Marathon",
                 date: calendar.date(byAdding: .month, value: 9, to: today)!,
                 city: "Valencia",
                 country: "Spain",
                 countryCode: "ES",
                 discipline: .running,
                 distance: .halfMarathon,
                 elevationGain: 10,
                 description: "The world's fastest half marathon. Flat, fast, and beautiful.",
                 registrationUrl: URL(string: "https://www.valenciaciudaddelrunning.com")!,
                 imageUrl: "valencia_img",
                 price: 60,
                 currency: "EUR",
                 registrationStatus: .unknown
             ),
             // 2026 Events
             RaceEvent(
                 id: UUID(),
                 name: "Tokyo Marathon 2026",
                 date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!,
                 city: "Tokyo",
                 country: "Japan",
                 countryCode: "JP",
                 discipline: .running,
                 distance: .marathon,
                 elevationGain: 10,
                 description: "Run through the heart of Tokyo in one of the world majors.",
                 registrationUrl: URL(string: "https://www.marathon.tokyo")!,
                 imageUrl: "tokyo_img",
                 price: 180,
                 currency: "USD",
                 registrationStatus: .closed
             ),
             RaceEvent(
                 id: UUID(),
                 name: "London Marathon 2026",
                 date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 26))!,
                 city: "London",
                 country: "UK",
                 countryCode: "GB",
                 discipline: .running,
                 distance: .marathon,
                 elevationGain: 40,
                 description: "The most popular marathon on the planet.",
                 registrationUrl: URL(string: "https://www.tcslondonmarathon.com")!,
                 imageUrl: "london_marathon_img",
                 price: 150,
                 currency: "GBP",
                 registrationStatus: .closed
             ),
             RaceEvent(
                 id: UUID(),
                 name: "Comrades Marathon 2026",
                 date: calendar.date(from: DateComponents(year: 2026, month: 6, day: 14))!,
                 city: "Durban",
                 country: "South Africa",
                 countryCode: "ZA",
                 discipline: .running,
                 distance: .ultraTrail,
                 elevationGain: 1200,
                 description: "The ultimate human race. Approx 90km.",
                 registrationUrl: URL(string: "https://www.comrades.com")!,
                 imageUrl: "comrades_img",
                 price: 200,
                 currency: "USD",
                 registrationStatus: .open
             ),
             RaceEvent(
                 id: UUID(),
                 name: "Ironman Nice 2026",
                 date: calendar.date(from: DateComponents(year: 2026, month: 6, day: 28))!,
                 city: "Nice",
                 country: "France",
                 countryCode: "FR",
                 discipline: .triathlon,
                 distance: .ironman,
                 elevationGain: 2000,
                 description: "Swim in the Mediterranean, ride in the Alps, run on the Promenade des Anglais.",
                 registrationUrl: URL(string: "https://www.ironman.com/im-france")!,
                 imageUrl: "nice_img",
                 price: 750,
                 currency: "EUR",
                 registrationStatus: .open
             ),
             RaceEvent(
                 id: UUID(),
                 name: "Chicago Marathon 2026",
                 date: calendar.date(from: DateComponents(year: 2026, month: 10, day: 11))!,
                 city: "Chicago",
                 country: "USA",
                 countryCode: "US",
                 discipline: .running,
                 distance: .marathon,
                 elevationGain: 0,
                 description: "Flat and fast. The home of the world record.",
                 registrationUrl: URL(string: "https://www.chicagomarathon.com")!,
                 imageUrl: "chicago_img",
                 price: 240,
                 currency: "USD",
                 registrationStatus: .open
             ),
             // 2027 Events - Planning ahead
             RaceEvent(
                 id: UUID(),
                 name: "Boston Marathon 2027",
                 date: calendar.date(from: DateComponents(year: 2027, month: 4, day: 19))!,
                 city: "Boston",
                 country: "USA",
                 countryCode: "US",
                 discipline: .running,
                 distance: .marathon,
                 elevationGain: 150,
                 description: "The oldest annual marathon in the world. Requires qualification.",
                 registrationUrl: URL(string: "https://www.baa.org")!,
                 imageUrl: "boston_img",
                 price: 250,
                 currency: "USD",
                 registrationStatus: .closed
             ),
             RaceEvent(
                 id: UUID(),
                 name: "UTMB 2027",
                 date: calendar.date(from: DateComponents(year: 2027, month: 8, day: 27))!,
                 city: "Chamonix",
                 country: "France",
                 countryCode: "FR",
                 discipline: .trail,
                 distance: .ultraTrail,
                 elevationGain: 10000,
                 description: "Projected dates for 2027 edition.",
                 registrationUrl: URL(string: "https://montblanc.utmb.world")!,
                 imageUrl: "utmb_img",
                 price: 400,
                 currency: "EUR",
                 registrationStatus: .closed
             ),
              RaceEvent(
                  id: UUID(),
                  name: "Sydney Marathon 2027",
                  date: calendar.date(from: DateComponents(year: 2027, month: 9, day: 19))!,
                  city: "Sydney",
                  country: "Australia",
                  countryCode: "AU",
                  discipline: .running,
                  distance: .marathon,
                  elevationGain: 250,
                  description: "Run across the Harbour Bridge. Candidate for World Major.",
                  registrationUrl: URL(string: "https://sydneymarathon.com")!,
                  imageUrl: "sydney_img",
                  price: 180,
                  currency: "AUD",
                  registrationStatus: .open
              ),
              // Additional 2026 Events
              RaceEvent(
                  id: UUID(),
                  name: "New York City Marathon 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 11, day: 1))!,
                  city: "New York",
                  country: "USA",
                  countryCode: "US",
                  discipline: .running,
                  distance: .marathon,
                  elevationGain: 200,
                  description: "The world's largest marathon through all five boroughs.",
                  registrationUrl: URL(string: "https://www.nyrr.org/tcsnycmarathon")!,
                  imageUrl: "nyc_img",
                  price: 295,
                  currency: "USD",
                  registrationStatus: .closed
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Marathon des Sables 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 3))!,
                  city: "Sahara Desert",
                  country: "Morocco",
                  countryCode: "MA",
                  discipline: .trail,
                  distance: .ultraTrail,
                  elevationGain: 800,
                  description: "The toughest footrace on Earth. 250km through the Sahara.",
                  registrationUrl: URL(string: "https://www.marathondessables.com")!,
                  imageUrl: "mds_img",
                  price: 3500,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Ironman 70.3 World Championship 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 9, day: 13))!,
                  city: "Lahti",
                  country: "Finland",
                  countryCode: "FI",
                  discipline: .triathlon,
                  distance: .halfIronman,
                  elevationGain: 600,
                  description: "The Half Ironman World Championship in scenic Finland.",
                  registrationUrl: URL(string: "https://www.ironman.com/im703-world-championship")!,
                  imageUrl: "im703_img",
                  price: 550,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Amsterdam Marathon 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 10, day: 18))!,
                  city: "Amsterdam",
                  country: "Netherlands",
                  countryCode: "NL",
                  discipline: .running,
                  distance: .marathon,
                  elevationGain: 0,
                  description: "Completely flat course through historic Amsterdam.",
                  registrationUrl: URL(string: "https://www.tcsamsterdammarathon.nl")!,
                  imageUrl: "amsterdam_img",
                  price: 100,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Two Oceans Marathon 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 11))!,
                  city: "Cape Town",
                  country: "South Africa",
                  countryCode: "ZA",
                  discipline: .running,
                  distance: .ultraTrail,
                  elevationGain: 900,
                  description: "The world's most beautiful marathon. 56km along the Cape coast.",
                  registrationUrl: URL(string: "https://www.twooceansmarathon.org.za")!,
                  imageUrl: "two_oceans_img",
                  price: 120,
                  currency: "USD",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Stockholm Marathon 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 5, day: 30))!,
                  city: "Stockholm",
                  country: "Sweden",
                  countryCode: "SE",
                  discipline: .running,
                  distance: .marathon,
                  elevationGain: 140,
                  description: "Run through the beautiful capital of Sweden.",
                  registrationUrl: URL(string: "https://www.stockholmmarathon.se")!,
                  imageUrl: "stockholm_img",
                  price: 95,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Eiger Ultra Trail 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 7, day: 18))!,
                  city: "Grindelwald",
                  country: "Switzerland",
                  countryCode: "CH",
                  discipline: .trail,
                  distance: .ultraTrail,
                  elevationGain: 6700,
                  description: "101km around the legendary Eiger North Face.",
                  registrationUrl: URL(string: "https://www.eigerultratrail.ch")!,
                  imageUrl: "eiger_img",
                  price: 200,
                  currency: "CHF",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Lisbon Half Marathon 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 22))!,
                  city: "Lisbon",
                  country: "Portugal",
                  countryCode: "PT",
                  discipline: .running,
                  distance: .halfMarathon,
                  elevationGain: 50,
                  description: "Cross the iconic 25 de Abril Bridge.",
                  registrationUrl: URL(string: "https://www.meialisboacapitalverde.com")!,
                  imageUrl: "lisbon_img",
                  price: 35,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Rome Marathon 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 15))!,
                  city: "Rome",
                  country: "Italy",
                  countryCode: "IT",
                  discipline: .running,
                  distance: .marathon,
                  elevationGain: 100,
                  description: "Run past the Colosseum and through ancient Rome.",
                  registrationUrl: URL(string: "https://www.runromethemarathon.com")!,
                  imageUrl: "rome_img",
                  price: 85,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Dubai Marathon 2027",
                  date: calendar.date(from: DateComponents(year: 2027, month: 1, day: 15))!,
                  city: "Dubai",
                  country: "UAE",
                  countryCode: "AE",
                  discipline: .running,
                  distance: .marathon,
                  elevationGain: 0,
                  description: "Ultra-fast course with big prize money.",
                  registrationUrl: URL(string: "https://www.dubaimarathon.org")!,
                  imageUrl: "dubai_img",
                  price: 100,
                  currency: "USD",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Cape Town Cycle Tour 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 8))!,
                  city: "Cape Town",
                  country: "South Africa",
                  countryCode: "ZA",
                  discipline: .running, // Would be cycling but we have running/trail/tri
                  distance: .marathon,
                  elevationGain: 600,
                  description: "109km around the Cape Peninsula. (Cycling event)",
                  registrationUrl: URL(string: "https://www.capetowncycletour.com")!,
                  imageUrl: "cape_cycle_img",
                  price: 80,
                  currency: "USD",
                  registrationStatus: .soldOut
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Rotterdam Marathon 2027",
                  date: calendar.date(from: DateComponents(year: 2027, month: 4, day: 11))!,
                  city: "Rotterdam",
                  country: "Netherlands",
                  countryCode: "NL",
                  discipline: .running,
                  distance: .marathon,
                  elevationGain: 0,
                  description: "One of the fastest marathon courses in Europe.",
                  registrationUrl: URL(string: "https://www.nnmarathonrotterdam.nl")!,
                  imageUrl: "rotterdam_img",
                  price: 90,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Western States 100 2027",
                  date: calendar.date(from: DateComponents(year: 2027, month: 6, day: 26))!,
                  city: "Olympic Valley",
                  country: "USA",
                  countryCode: "US",
                  discipline: .trail,
                  distance: .ultraTrail,
                  elevationGain: 5500,
                  description: "The oldest 100-mile trail race. Squaw Valley to Auburn.",
                  registrationUrl: URL(string: "https://www.wser.org")!,
                  imageUrl: "wser_img",
                  price: 450,
                  currency: "USD",
                  registrationStatus: .closed
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Ironman Barcelona 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 10, day: 4))!,
                  city: "Calella",
                  country: "Spain",
                  countryCode: "ES",
                  discipline: .triathlon,
                  distance: .ironman,
                  elevationGain: 1100,
                  description: "Mediterranean swim, scenic bike, fast run.",
                  registrationUrl: URL(string: "https://www.ironman.com/im-barcelona")!,
                  imageUrl: "barcelona_img",
                  price: 700,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Copenhagen Half Marathon 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 9, day: 13))!,
                  city: "Copenhagen",
                  country: "Denmark",
                  countryCode: "DK",
                  discipline: .running,
                  distance: .halfMarathon,
                  elevationGain: 20,
                  description: "Fast and scenic through the Danish capital.",
                  registrationUrl: URL(string: "https://www.copenhagenhalf.dk")!,
                  imageUrl: "copenhagen_img",
                  price: 55,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              // Added Moroccan & Spanish Events
              RaceEvent(
                  id: UUID(),
                  name: "Marrakech Marathon 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 1, day: 25))!,
                  city: "Marrakech",
                  country: "Morocco",
                  countryCode: "MA",
                  discipline: .running,
                  distance: .marathon,
                  elevationGain: 50,
                  description: "Run under the palm trees and along the ramparts of the Red City.",
                  registrationUrl: URL(string: "https://www.marathon-marrakech.com")!,
                  imageUrl: "marrakech_img",
                  price: 70,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Madrid Marathon 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 26))!,
                  city: "Madrid",
                  country: "Spain",
                  countryCode: "ES",
                  discipline: .running,
                  distance: .marathon,
                  elevationGain: 300,
                  description: "Rock 'n' Roll Marathon through the heart of the Spanish capital.",
                  registrationUrl: URL(string: "https://rocknrollmadridrun.com")!,
                  imageUrl: "madrid_img",
                  price: 85,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Rabat Marathon 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 5, day: 10))!,
                  city: "Rabat",
                  country: "Morocco",
                  countryCode: "MA",
                  discipline: .running,
                  distance: .marathon,
                  elevationGain: 80,
                  description: "Discover the Royal Capital of Morocco.",
                  registrationUrl: URL(string: "https://www.rabatmarathon.com")!,
                  imageUrl: "rabat_img",
                  price: 50,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Casablanca Marathon 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 10, day: 25))!,
                  city: "Casablanca",
                  country: "Morocco",
                  countryCode: "MA",
                  discipline: .running,
                  distance: .marathon,
                  elevationGain: 60,
                  description: "Run through the economic heart of Morocco.",
                  registrationUrl: URL(string: "https://www.casablanca-marathon.com")!,
                  imageUrl: "casablanca_img",
                  price: 40,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Malaga Marathon 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 11, day: 8))!,
                  city: "Malaga",
                  country: "Spain",
                  countryCode: "ES",
                  discipline: .running,
                  distance: .marathon,
                  elevationGain: 40,
                  description: "Sunny winter marathon on the Costa del Sol.",
                  registrationUrl: URL(string: "https://www.generalimaratonmalaga.com")!,
                  imageUrl: "malaga_img",
                  price: 65,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              // Added Turkey Events
              RaceEvent(
                  id: UUID(),
                  name: "Cappadocia Ultra-Trail 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 10, day: 17))!,
                  city: "Urgup",
                  country: "Turkey",
                  countryCode: "TR",
                  discipline: .trail,
                  distance: .ultraTrail,
                  elevationGain: 3730,
                  description: "Run through the fairy chimneys and unique rock formations of Cappadocia.",
                  registrationUrl: URL(string: "https://cappadociaultratrail.com")!,
                  imageUrl: "cappadocia_img",
                  price: 150,
                  currency: "EUR",
                  registrationStatus: .open
              ),
               RaceEvent(
                  id: UUID(),
                  name: "Iznik Ultra Marathon 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 10))!,
                  city: "Iznik",
                  country: "Turkey",
                  countryCode: "TR",
                  discipline: .trail,
                  distance: .ultraTrail,
                  elevationGain: 2500,
                  description: "Run around the historic Iznik Lake.",
                  registrationUrl: URL(string: "https://www.iznikultra.com")!,
                  imageUrl: "iznik_img",
                  price: 80,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Antalya Marathon 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 5))!,
                  city: "Antalya",
                  country: "Turkey",
                  countryCode: "TR",
                  discipline: .running,
                  distance: .marathon,
                  elevationGain: 50,
                  description: "Run along the beautiful Mediterranean coast.",
                  registrationUrl: URL(string: "https://www.antalayamarathon.com")!,
                  imageUrl: "antalya_img",
                  price: 60,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Bodrum Half Marathon 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 10, day: 4))!,
                  city: "Bodrum",
                  country: "Turkey",
                  countryCode: "TR",
                  discipline: .running,
                  distance: .halfMarathon,
                  elevationGain: 100,
                  description: "Scenic half marathon in the Aegean paradise.",
                  registrationUrl: URL(string: "https://bodrumyarimaratonu.com")!,
                  imageUrl: "bodrum_img",
                  price: 40,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Lycian Way Ultra 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 9, day: 26))!,
                  city: "Kas",
                  country: "Turkey",
                  countryCode: "TR",
                  discipline: .trail,
                  distance: .ultraTrail,
                  elevationGain: 3000,
                  description: "A historic trail run on the Lycian Way.",
                  registrationUrl: URL(string: "https://likyayoluultramaratonu.com")!,
                  imageUrl: "lycian_img",
                  price: 120,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              // Added More Moroccan Trails
              RaceEvent(
                  id: UUID(),
                  name: "Eco Trail Morocco 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 14))!,
                  city: "Ouarzazate",
                  country: "Morocco",
                  countryCode: "MA",
                  discipline: .trail,
                  distance: .ultraTrail,
                  elevationGain: 1500,
                  description: "Discover the gates of the desert.",
                  registrationUrl: URL(string: "https://ecotrailmorocco.com")!,
                  imageUrl: "ecotrail_img",
                  price: 180,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              RaceEvent(
                  id: UUID(),
                  name: "Nomad Trail Zagora 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 11, day: 8))!,
                  city: "Zagora",
                  country: "Morocco",
                  countryCode: "MA",
                  discipline: .trail,
                  distance: .ultraTrail,
                  elevationGain: 800,
                  description: "Run through the dunes and oasis of Zagora.",
                  registrationUrl: URL(string: "https://nomadtrail.com")!,
                  imageUrl: "zagora_img",
                  price: 100,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              // Added Spanish Half
              RaceEvent(
                  id: UUID(),
                  name: "Malaga Half Marathon 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 15))!,
                  city: "Malaga",
                  country: "Spain",
                  countryCode: "ES",
                  discipline: .running,
                  distance: .halfMarathon,
                  elevationGain: 30,
                  description: "Fast and flat course on the Costa del Sol.",
                  registrationUrl: URL(string: "https://www.mediamaratonmalaga.com")!,
                  imageUrl: "malaga_half_img",
                  price: 35,
                  currency: "EUR",
                  registrationStatus: .open
              ),
              // Added Global Major
              RaceEvent(
                  id: UUID(),
                  name: "Great Wall Marathon 2026",
                  date: calendar.date(from: DateComponents(year: 2026, month: 5, day: 16))!,
                  city: "Beijing",
                  country: "China",
                  countryCode: "CN",
                  discipline: .running,
                  distance: .marathon,
                  elevationGain: 3000,
                  description: "5,164 steps into history on the Great Wall of China.",
                  registrationUrl: URL(string: "https://great-wall-marathon.com")!,
                  imageUrl: "greatwall_img",
                  price: 1300,
                  currency: "USD",
                  registrationStatus: .open
              )
        ]
    }
}

// MARK: - Date Formatter
private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f
}()

// MARK: - Remote Events Wrapper (new JSON format)
struct RemoteEventsWrapper: Codable {
    let lastUpdated: String
    let totalEvents: Int
    let events: [RemoteRaceEvent]
}

// MARK: - Remote Event Decoder
struct RemoteRaceEvent: Codable {
    let id: String
    let name: String
    let date: String
    let city: String
    let country: String
    let countryCode: String
    let discipline: String
    let distance: String
    let elevationGain: Int?
    let description: String
    let registrationUrl: String
    let imageUrl: String
    let price: Double?
    let currency: String?
    let registrationStatus: String?
    
    func toRaceEvent() -> RaceEvent {
        let disc: Discipline = {
            switch discipline.lowercased() {
            case "running": return .running
            case "trail": return .trail
            case "triathlon": return .triathlon
            default: return .running
            }
        }()
        
        let dist: Distance = {
            switch distance.lowercased() {
            case "marathon": return .marathon
            case "half marathon": return .halfMarathon
            case "10km": return .tenKm
            case "5km": return .fiveKm
            case "ultra trail": return .ultraTrail
            case "ironman": return .ironman
            case "half ironman": return .halfIronman
            default: return .marathon
            }
        }()
        
        let status: RegistrationStatus? = {
            guard let statusStr = registrationStatus else { return nil }
            switch statusStr.lowercased() {
            case "open": return .open
            case "closed": return .closed
            case "soldout", "sold out": return .soldOut
            default: return nil
            }
        }()
        
        let eventDate = dateFormatter.date(from: date) ?? Date()
        
        return RaceEvent(
            id: UUID(),
            name: name,
            date: eventDate,
            city: city,
            country: country,
            countryCode: countryCode,
            discipline: disc,
            distance: dist,
            elevationGain: elevationGain,
            description: description,
            registrationUrl: URL(string: registrationUrl) ?? URL(string: "https://example.com")!,
            imageUrl: imageUrl,
            price: price,
            currency: currency,
            registrationStatus: status
        )
    }
}
