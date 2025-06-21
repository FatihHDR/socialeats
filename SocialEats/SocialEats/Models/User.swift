import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let displayName: String
    let photoURL: String?
    let createdAt: Date
    var friends: [String] // Array of user IDs
    var selectedRestaurant: SelectedRestaurant?
    
    init(id: String, email: String, displayName: String, photoURL: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = Date()
        self.friends = []
        self.selectedRestaurant = nil
    }
}

struct SelectedRestaurant: Codable {
    let restaurantId: String
    let restaurantName: String
    let selectedAt: Date
    let expiresAt: Date
    
    init(restaurantId: String, restaurantName: String) {
        self.restaurantId = restaurantId
        self.restaurantName = restaurantName
        self.selectedAt = Date()
        self.expiresAt = Calendar.current.date(byAdding: .hour, value: 12, to: Date()) ?? Date()
    }
    
    var isExpired: Bool {
        return Date() > expiresAt
    }
}
