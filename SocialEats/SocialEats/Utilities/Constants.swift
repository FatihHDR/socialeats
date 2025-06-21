import Foundation

struct Constants {
    // MARK: - API Keys
    static let googleMapsAPIKey = "YOUR_GOOGLE_MAPS_API_KEY"
    static let googlePlacesAPIKey = "YOUR_GOOGLE_PLACES_API_KEY"
    
    // MARK: - Firebase Collections
    static let usersCollection = "users"
    static let friendRequestsCollection = "friend_requests"
    
    // MARK: - Restaurant Selection
    static let selectionExpiryHours = 12
    static let defaultSearchRadius = 1500 // meters
    
    // MARK: - User Defaults Keys
    static let hasSeenOnboarding = "hasSeenOnboarding"
    static let lastLocationUpdate = "lastLocationUpdate"
    
    // MARK: - Notifications
    static let friendRequestReceived = "friendRequestReceived"
    static let friendSelectedRestaurant = "friendSelectedRestaurant"
}
