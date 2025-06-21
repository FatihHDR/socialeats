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
            }            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFriend = true
                    }) {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 18, weight: .medium))
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
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.orange.opacity(0.7))
                                )
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
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
        HStack(spacing: 16) {
            // Profile Picture with enhanced design
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: friend.photoURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.orange.opacity(0.7))
                        )
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Online status indicator
                if friend.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 2, y: 2)
                }
            }
            
            // Friend Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(friend.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                Text(friend.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let selectedRestaurant = friend.selectedRestaurant,
                   !selectedRestaurant.isExpired {
                    HStack(spacing: 6) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                        Text("Dining at \(selectedRestaurant.restaurantName)")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
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
        HStack(spacing: 16) {
            // Profile Picture
            AsyncImage(url: URL(string: friend.photoURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.orange.opacity(0.7))
                    )
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Friend and Restaurant Info
            VStack(alignment: .leading, spacing: 8) {
                Text(friend.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let selectedRestaurant = friend.selectedRestaurant {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                            Text(selectedRestaurant.restaurantName)
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("Until \(selectedRestaurant.expiresAt, style: .time)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    FriendsView()
        .environmentObject(AuthenticationService())
}
