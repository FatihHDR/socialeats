import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthenticationService()
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
                    .environmentObject(authService)
            } else {
                AuthenticationView()
                    .environmentObject(authService)
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        TabView {
            RestaurantsView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Restaurants")
                }
            
            FriendsView()
                .tabItem {
                    Image(systemName: "person.2")
                    Text("Friends")
                }
        }
        .environmentObject(authService)
    }
}

#Preview {
    ContentView()
}
