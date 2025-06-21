import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthenticationService()
    @EnvironmentObject var notificationService: NotificationService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
                    .environmentObject(authService)
                    .environmentObject(notificationService)
            } else {
                AuthenticationView()
                    .environmentObject(authService)
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var notificationService: NotificationService
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RestaurantsView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Restaurants")
                }
                .tag(0)
            
            FriendsView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Friends")
                }
                .tag(1)
        }
        .environmentObject(authService)
        .accentColor(.orange)
        .onReceive(NotificationCenter.default.publisher(for: .showFriendsTab)) { _ in
            selectedTab = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: .showRestaurantsTab)) { _ in
            selectedTab = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .showFriendRequests)) { _ in
            selectedTab = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: .showRestaurantReviews)) { notification in
            selectedTab = 0
            // Handle specific restaurant navigation if needed
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NotificationService())
}
