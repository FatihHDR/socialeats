import Foundation

struct GroupDining: Codable, Identifiable {
    let id: String
    let restaurantId: String
    let restaurantName: String
    let restaurantAddress: String
    let organizerId: String
    let organizerName: String
    let title: String
    let description: String
    let scheduledDate: Date
    let maxParticipants: Int
    let currentParticipants: [String] // Array of user IDs
    let invitedUsers: [String] // Array of user IDs
    let createdAt: Date
    let updatedAt: Date
    let status: GroupDiningStatus
    
    init(restaurantId: String, restaurantName: String, restaurantAddress: String, organizerId: String, organizerName: String, title: String, description: String, scheduledDate: Date, maxParticipants: Int) {
        self.id = UUID().uuidString
        self.restaurantId = restaurantId
        self.restaurantName = restaurantName
        self.restaurantAddress = restaurantAddress
        self.organizerId = organizerId
        self.organizerName = organizerName
        self.title = title
        self.description = description
        self.scheduledDate = scheduledDate
        self.maxParticipants = maxParticipants
        self.currentParticipants = [organizerId] // Organizer is automatically a participant
        self.invitedUsers = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.status = .active
    }
    
    var isExpired: Bool {
        return Date() > scheduledDate
    }
    
    var isFull: Bool {
        return currentParticipants.count >= maxParticipants
    }
    
    var availableSpots: Int {
        return maxParticipants - currentParticipants.count
    }
}

enum GroupDiningStatus: String, Codable, CaseIterable {
    case active = "active"
    case cancelled = "cancelled"
    case completed = "completed"
}

struct GroupDiningInvitation: Codable, Identifiable {
    let id: String
    let groupDiningId: String
    let fromUserId: String
    let toUserId: String
    let fromUserName: String
    let groupTitle: String
    let restaurantName: String
    let scheduledDate: Date
    let sentAt: Date
    let status: InvitationStatus
}

enum InvitationStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
}
