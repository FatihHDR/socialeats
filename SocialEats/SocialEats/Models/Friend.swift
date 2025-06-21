import Foundation

struct Friend: Codable, Identifiable {
    let id: String
    let displayName: String
    let email: String
    let photoURL: String?
    let selectedRestaurant: SelectedRestaurant?
    let lastSeen: Date
    
    var isOnline: Bool {
        let fiveMinutesAgo = Calendar.current.date(byAdding: .minute, value: -5, to: Date()) ?? Date()
        return lastSeen > fiveMinutesAgo
    }
}

struct FriendRequest: Codable, Identifiable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let fromUserName: String
    let fromUserEmail: String
    let fromUserPhotoURL: String?
    let sentAt: Date
    let status: FriendRequestStatus
}

enum FriendRequestStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
}
