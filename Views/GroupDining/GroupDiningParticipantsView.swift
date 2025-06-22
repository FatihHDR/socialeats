import SwiftUI

struct GroupDiningParticipantsView: View {
    let groupDining: GroupDining
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var userService = UserService()
    @State private var participants: [User] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(participants) { participant in
                        HStack {
                            AsyncImage(url: URL(string: participant.photoURL ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.gray)
                                    )
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(participant.displayName)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text(participant.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if participant.id == groupDining.organizerId {
                                Text("Organizer")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Participants (\(participants.count)/\(groupDining.maxParticipants))")
                }
                
                if participants.count < groupDining.maxParticipants {
                    Section {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.orange)
                            Text("Invite more friends")
                                .foregroundColor(.orange)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Handle invite action
                        }
                    }
                }
            }
            .navigationTitle("Participants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                loadParticipants()
            }
        }
    }
    
    private func loadParticipants() {
        isLoading = true
        
        let group = DispatchGroup()
        var loadedParticipants: [User] = []
        
        for participantId in groupDining.currentParticipants {
            group.enter()
            userService.getUser(userId: participantId) { user in
                if let user = user {
                    loadedParticipants.append(user)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.participants = loadedParticipants.sorted { user1, user2 in
                if user1.id == groupDining.organizerId { return true }
                if user2.id == groupDining.organizerId { return false }
                return user1.displayName < user2.displayName
            }
            self.isLoading = false
        }
    }
}

struct InviteFriendsToGroupView: View {
    let groupDining: GroupDining
    @ObservedObject var viewModel: GroupDiningViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var friendsViewModel = FriendsViewModel(authService: AuthenticationService())
    @State private var selectedFriends: Set<String> = []
    @State private var isInviting = false
    
    var availableFriends: [Friend] {
        return friendsViewModel.friends.filter { friend in
            !groupDining.currentParticipants.contains(friend.id) &&
            !groupDining.invitedUsers.contains(friend.id)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if availableFriends.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No friends available to invite")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("All your friends are either already in this group or have been invited.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        Section {
                            ForEach(availableFriends) { friend in
                                HStack {
                                    AsyncImage(url: URL(string: friend.photoURL ?? "")) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(.gray)
                                            )
                                    }
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(friend.displayName)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        Text(friend.email)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedFriends.contains(friend.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.orange)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if selectedFriends.contains(friend.id) {
                                        selectedFriends.remove(friend.id)
                                    } else {
                                        selectedFriends.insert(friend.id)
                                    }
                                }
                            }
                        } header: {
                            Text("Select friends to invite")
                        }
                    }
                    
                    // Invite button
                    if !selectedFriends.isEmpty {
                        VStack {
                            Button(action: sendInvitations) {
                                HStack {
                                    if isInviting {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "paperplane.fill")
                                    }
                                    Text(isInviting ? "Sending..." : "Invite \(selectedFriends.count) friend\(selectedFriends.count == 1 ? "" : "s")")
                                }
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.orange)
                                .cornerRadius(12)
                            }
                            .disabled(isInviting)
                            .padding()
                        }
                        .background(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                    }
                }
            }
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                friendsViewModel.loadFriends()
            }
        }
    }
    
    private func sendInvitations() {
        isInviting = true
        
        let group = DispatchGroup()
        var successCount = 0
        
        for friendId in selectedFriends {
            guard let friend = friendsViewModel.friends.first(where: { $0.id == friendId }) else { continue }
            
            group.enter()
            viewModel.inviteFriendToGroupDining(groupDining, friendId: friend.id, friendName: friend.displayName) { success in
                if success {
                    successCount += 1
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.isInviting = false
            if successCount > 0 {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

#Preview {
    GroupDiningParticipantsView(
        groupDining: GroupDining(
            restaurantId: "1",
            restaurantName: "Sample Restaurant",
            restaurantAddress: "123 Main St",
            organizerId: "user1",
            organizerName: "John Doe",
            title: "Friday Night Dinner",
            description: "Let's try this new place!",
            scheduledDate: Date().addingTimeInterval(86400),
            maxParticipants: 6
        )
    )
}
