import Foundation
import Combine
import Contacts

class FriendsViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var searchResults: [User] = []
    
    private let userService = UserService()
    var authService: AuthenticationService?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthenticationService) {
        self.authService = authService
        setupBindings()
        loadFriends()
    }
    
    private func setupBindings() {
        // Auto-search when search text changes
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                if !searchText.isEmpty {
                    self?.searchUsers(query: searchText)
                } else {
                    self?.searchResults = []
                }
            }
            .store(in: &cancellables)
        
        // Reload friends when current user changes
        authService?.$currentUser
            .sink { [weak self] _ in
                self?.loadFriends()
            }
            .store(in: &cancellables)
    }
    
    func loadFriends() {
        guard let currentUser = authService?.currentUser else { return }
        
        isLoading = true
        userService.getFriends(for: currentUser) { [weak self] friends in
            DispatchQueue.main.async {
                self?.friends = friends
                self?.isLoading = false
            }
        }
    }
    
    func searchUsers(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        // Search by email (you might want to expand this to include name search)
        userService.searchUsers(by: query) { [weak self] users in
            DispatchQueue.main.async {
                // Filter out current user and existing friends
                let currentUserId = self?.authService?.currentUser?.id
                let friendIds = Set(self?.friends.map { $0.id } ?? [])
                
                self?.searchResults = users.filter { user in
                    user.id != currentUserId && !friendIds.contains(user.id)
                }
            }
        }
    }
    
    func sendFriendRequest(to user: User) {
        guard let currentUser = authService?.currentUser else { return }
        
        let friendRequest = FriendRequest(
            id: UUID().uuidString,
            fromUserId: currentUser.id,
            toUserId: user.id,
            fromUserName: currentUser.displayName,
            fromUserEmail: currentUser.email,
            fromUserPhotoURL: currentUser.photoURL,
            sentAt: Date(),
            status: .pending
        )
        
        // In a real app, you'd save this to Firestore
        // For now, just add them as friends directly
        addFriend(user)
    }
    
    func addFriend(_ user: User) {
        guard let currentUser = authService?.currentUser else { return }
        
        userService.addFriend(userId: currentUser.id, friendId: user.id) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    let friend = Friend(
                        id: user.id,
                        displayName: user.displayName,
                        email: user.email,
                        photoURL: user.photoURL,
                        selectedRestaurant: user.selectedRestaurant,
                        lastSeen: Date()
                    )
                    self?.friends.append(friend)
                } else {
                    self?.errorMessage = "Failed to add friend"
                }
            }
        }
    }
    
    func removeFriend(_ friend: Friend) {
        guard let currentUser = authService?.currentUser else { return }
        
        userService.removeFriend(userId: currentUser.id, friendId: friend.id) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.friends.removeAll { $0.id == friend.id }
                } else {
                    self?.errorMessage = "Failed to remove friend"
                }
            }
        }
    }
    
    func getFriendsWithSelectedRestaurants() -> [Friend] {
        return friends.filter { friend in
            guard let selectedRestaurant = friend.selectedRestaurant else { return false }
            return !selectedRestaurant.isExpired
        }
    }
    
    func getFriendsAtRestaurant(_ restaurantId: String) -> [Friend] {
        return friends.filter { friend in
            guard let selectedRestaurant = friend.selectedRestaurant else { return false }
            return selectedRestaurant.restaurantId == restaurantId && !selectedRestaurant.isExpired
        }
    }
    
    func requestContactsAccess() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { [weak self] granted, error in
            if granted {
                self?.loadContactsAndSuggestFriends()
            } else {
                DispatchQueue.main.async {
                    self?.errorMessage = "Contacts access denied"
                }
            }
        }
    }
    
    private func loadContactsAndSuggestFriends() {
        let store = CNContactStore()
        let keys = [CNContactEmailAddressesKey, CNContactGivenNameKey, CNContactFamilyNameKey]
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        
        var contactEmails: [String] = []
        
        do {
            try store.enumerateContacts(with: request) { contact, _ in
                for emailAddress in contact.emailAddresses {
                    contactEmails.append(emailAddress.value as String)
                }
            }
            
            // Search for users with matching emails
            for email in contactEmails {
                searchUsers(query: email)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load contacts"
            }
        }
    }
}
