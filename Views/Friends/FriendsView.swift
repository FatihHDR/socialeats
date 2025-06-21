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
        VStack(spacing: 32) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 72, weight: .ultraLight))
                .foregroundColor(.orange.opacity(0.3))
            
            VStack(spacing: 16) {
                Text("Connect with Friends")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Add friends to discover where they're dining and share your own restaurant experiences together.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Button(action: onAddFriend) {
                HStack(spacing: 12) {
                    Image(systemName: "person.badge.plus.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("Add Your First Friend")
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.orange.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(48)
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
