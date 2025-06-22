import Foundation

struct RestaurantPhoto: Codable, Identifiable {
    let id: String
    let restaurantId: String
    let restaurantName: String
    let userId: String
    let userName: String
    let userPhotoURL: String?
    let photoURL: String
    let caption: String?
    let tags: [String] // Tags like "food", "interior", "menu", etc.
    let likes: [String] // Array of user IDs who liked
    let createdAt: Date
    let updatedAt: Date
    let isVerified: Bool // True if user was at the restaurant when photo was taken
    
    init(restaurantId: String, restaurantName: String, userId: String, userName: String, userPhotoURL: String?, photoURL: String, caption: String? = nil, tags: [String] = [], isVerified: Bool = false) {
        self.id = UUID().uuidString
        self.restaurantId = restaurantId
        self.restaurantName = restaurantName
        self.userId = userId
        self.userName = userName
        self.userPhotoURL = userPhotoURL
        self.photoURL = photoURL
        self.caption = caption
        self.tags = tags
        self.likes = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isVerified = isVerified
    }
    
    var likeCount: Int {
        return likes.count
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

struct PhotoTag: Codable, Identifiable {
    let id: String
    let name: String
    let emoji: String
    let color: String // Hex color code
    
    static let predefinedTags = [
        PhotoTag(id: "food", name: "Food", emoji: "🍽️", color: "#FF6B35"),
        PhotoTag(id: "drinks", name: "Drinks", emoji: "🍹", color: "#4ECDC4"),
        PhotoTag(id: "interior", name: "Interior", emoji: "🏛️", color: "#45B7D1"),
        PhotoTag(id: "menu", name: "Menu", emoji: "📋", color: "#96CEB4"),
        PhotoTag(id: "dessert", name: "Dessert", emoji: "🍰", color: "#FFEAA7"),
        PhotoTag(id: "group", name: "Group", emoji: "👥", color: "#DDA0DD"),
        PhotoTag(id: "special", name: "Special Dish", emoji: "⭐", color: "#FFD93D"),
        PhotoTag(id: "view", name: "View", emoji: "🏞️", color: "#6C5CE7")
    ]
}

extension PhotoTag {
    init(id: String, name: String, emoji: String, color: String) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.color = color
    }
}
