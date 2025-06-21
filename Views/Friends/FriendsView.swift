import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var viewModel: FriendsViewModel
    @State private var showingAddFriend = false
    @State private var showingUserProfile = false
    
    init() {
        _viewModel = StateObject(wrappedValue: FriendsViewModel(authService: AuthenticationService()))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.friends.isEmpty && !viewModel.isLoading {
                    EmptyFriendsView {
                        showingAddFriend = true
                    }
                } else {
                    List {
                        // Friends with selected restaurants
                        let friendsWithRestaurants = viewModel.getFriendsWithSelectedRestaurants()
                        if !friendsWithRestaurants.isEmpty {
                            Section(header: Text("Friends at Restaurants")) {
                                ForEach(friendsWithRestaurants) { friend in
                                    FriendWithRestaurantRow(friend: friend)
                                }
                            }
                        }
                        
                        // All friends
                        Section(header: Text("All Friends")) {
                            ForEach(viewModel.friends) { friend in
                                FriendRow(friend: friend) {
                                    viewModel.removeFriend(friend)
                                }
                            }
                        }
                    }
                    .refreshable {
                        viewModel.loadFriends()
                    }
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFriend = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.orange)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingUserProfile = true
                    }) {
                        AsyncImage(url: URL(string: authService.currentUser?.photoURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.crop.circle")
                                .foregroundColor(.orange)
                        }
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingUserProfile) {
                UserProfileView()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .onAppear {
            viewModel.authService = authService
        }
    }
}

struct EmptyFriendsView: View {
    let onAddFriend: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Friends Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add friends to see where they're dining!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onAddFriend) {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Add Friends")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.orange)
                .cornerRadius(12)
            }
        }
        .padding(40)
    }
}

struct FriendRow: View {
    let friend: Friend
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            AsyncImage(url: URL(string: friend.photoURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // Friend Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(friend.displayName)
                        .font(.headline)
                    
                    Spacer()
                    
                    if friend.isOnline {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(friend.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let selectedRestaurant = friend.selectedRestaurant,
                   !selectedRestaurant.isExpired {
                    Text("At: \(selectedRestaurant.restaurantName)")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
        }
        .contextMenu {
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Remove Friend", systemImage: "trash")
            }
        }
    }
}

struct FriendWithRestaurantRow: View {
    let friend: Friend
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            AsyncImage(url: URL(string: friend.photoURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // Friend and Restaurant Info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(.headline)
                
                if let selectedRestaurant = friend.selectedRestaurant {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedRestaurant.restaurantName)
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                        
                        Text("Until: \(selectedRestaurant.expiresAt, style: .time)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "fork.knife.circle.fill")
                .foregroundColor(.orange)
                .font(.title2)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FriendsView()
        .environmentObject(AuthenticationService())
}
