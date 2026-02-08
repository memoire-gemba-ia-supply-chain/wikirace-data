import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(AppStrings.tabExplore, systemImage: "magnifyingglass")
                }
            
            MyEventsView()
                .tabItem {
                    Label("My Races", systemImage: "calendar")
                }
            
            HealthTrackingView(profile: .init(get: { RaceDataService.shared.userProfile }, set: { RaceDataService.shared.userProfile = $0 }))
                .tabItem {
                    Label("Health", systemImage: "heart.text.square")
                }
        }
        .preferredColorScheme(.dark)
        .accentColor(.themeBlue)
    }
}
