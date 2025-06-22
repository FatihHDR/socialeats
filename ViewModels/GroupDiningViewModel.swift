import Foundation
import Combine

class GroupDiningViewModel: ObservableObject {
    @Published var groupDinings: [GroupDining] = []
    @Published var userGroupDinings: [GroupDining] = []
    @Published var invitations: [GroupDiningInvitation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let groupDiningService = GroupDiningService()
    private let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthenticationService) {
        self.authService = authService
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind loading state
        groupDiningService.$isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        // Bind error messages
        groupDiningService.$errorMessage
            .compactMap { $0 }
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }
    
    func loadGroupDinings() {
        guard let currentUser = authService.currentUser else { return }
        
        // Load user's group dinings
        groupDiningService.getGroupDinings(for: currentUser.id) { [weak self] groupDinings in
            DispatchQueue.main.async {
                self?.userGroupDinings = groupDinings
            }
        }
        
        // Load upcoming group dinings from friends
        loadUpcomingGroupDinings()
        
        // Load invitations
        loadInvitations()
    }
    
    private func loadUpcomingGroupDinings() {
        groupDiningService.getUpcomingGroupDinings { [weak self] groupDinings in
            DispatchQueue.main.async {
                self?.groupDinings = groupDinings
            }
        }
    }
    
    private func loadInvitations() {
        guard let currentUser = authService.currentUser else { return }
        
        groupDiningService.getGroupDiningInvitations(for: currentUser.id) { [weak self] invitations in
            DispatchQueue.main.async {
                self?.invitations = invitations
            }
        }
    }
    
    func createGroupDining(
        restaurantId: String,
        restaurantName: String,
        restaurantAddress: String,
        title: String,
        description: String,
        scheduledDate: Date,
        maxParticipants: Int,
        completion: @escaping (Bool) -> Void
    ) {
        guard let currentUser = authService.currentUser else {
            completion(false)
            return
        }
        
        let groupDining = GroupDining(
            restaurantId: restaurantId,
            restaurantName: restaurantName,
            restaurantAddress: restaurantAddress,
            organizerId: currentUser.id,
            organizerName: currentUser.displayName,
            title: title,
            description: description,
            scheduledDate: scheduledDate,
            maxParticipants: maxParticipants
        )
        
        groupDiningService.createGroupDining(groupDining) { [weak self] success in
            if success {
                self?.loadGroupDinings()
            }
            completion(success)
        }
    }
    
    func joinGroupDining(_ groupDining: GroupDining, completion: @escaping (Bool) -> Void) {
        guard let currentUser = authService.currentUser else {
            completion(false)
            return
        }
        
        groupDiningService.joinGroupDining(groupDining.id, userId: currentUser.id) { [weak self] success in
            if success {
                self?.loadGroupDinings()
            }
            completion(success)
        }
    }
    
    func leaveGroupDining(_ groupDining: GroupDining, completion: @escaping (Bool) -> Void) {
        guard let currentUser = authService.currentUser else {
            completion(false)
            return
        }
        
        groupDiningService.leaveGroupDining(groupDining.id, userId: currentUser.id) { [weak self] success in
            if success {
                self?.loadGroupDinings()
            }
            completion(success)
        }
    }
    
    func inviteFriendToGroupDining(_ groupDining: GroupDining, friendId: String, friendName: String, completion: @escaping (Bool) -> Void) {
        guard let currentUser = authService.currentUser else {
            completion(false)
            return
        }
        
        let invitation = GroupDiningInvitation(
            id: UUID().uuidString,
            groupDiningId: groupDining.id,
            fromUserId: currentUser.id,
            toUserId: friendId,
            fromUserName: currentUser.displayName,
            groupTitle: groupDining.title,
            restaurantName: groupDining.restaurantName,
            scheduledDate: groupDining.scheduledDate,
            sentAt: Date(),
            status: .pending
        )
        
        groupDiningService.sendGroupDiningInvitation(invitation) { success in
            completion(success)
        }
    }
    
    func respondToInvitation(_ invitation: GroupDiningInvitation, response: InvitationStatus, completion: @escaping (Bool) -> Void) {
        groupDiningService.respondToInvitation(invitation.id, response: response) { [weak self] success in
            if success {
                self?.loadInvitations()
                if response == .accepted {
                    self?.loadGroupDinings()
                }
            }
            completion(success)
        }
    }
    
    func cancelGroupDining(_ groupDining: GroupDining, completion: @escaping (Bool) -> Void) {
        groupDiningService.cancelGroupDining(groupDining.id) { [weak self] success in
            if success {
                self?.loadGroupDinings()
            }
            completion(success)
        }
    }
    
    func canJoinGroupDining(_ groupDining: GroupDining) -> Bool {
        guard let currentUser = authService.currentUser else { return false }
        
        // Check if user is already a participant
        if groupDining.currentParticipants.contains(currentUser.id) {
            return false
        }
        
        // Check if group is full
        if groupDining.isFull {
            return false
        }
        
        // Check if event is expired
        if groupDining.isExpired {
            return false
        }
        
        // Check if group is active
        if groupDining.status != .active {
            return false
        }
        
        return true
    }
    
    func canLeaveGroupDining(_ groupDining: GroupDining) -> Bool {
        guard let currentUser = authService.currentUser else { return false }
        
        // Organizer cannot leave their own group
        if groupDining.organizerId == currentUser.id {
            return false
        }
        
        // Check if user is a participant
        return groupDining.currentParticipants.contains(currentUser.id)
    }
    
    func getGroupDiningsForRestaurant(_ restaurantId: String, completion: @escaping ([GroupDining]) -> Void) {
        groupDiningService.getGroupDiningsForRestaurant(restaurantId, completion: completion)
    }
}
