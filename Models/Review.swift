import Foundation

struct RestaurantReview: Codable, Identifiable {
    let id: String
    let restaurantId: String
    let restaurantName: String
    let userId: String
    let userName: String
    let userPhotoURL: String?
    let rating: Double // 1.0 to 5.0
    let reviewText: String
    let photos: [String] // Photo URLs
    let createdAt: Date
    let updatedAt: Date
    let likes: [String] // Array of user IDs who liked
    let isVerifiedVisit: Bool // True if user actually selected this restaurant
    
    init(restaurantId: String, restaurantName: String, userId: String, userName: String, userPhotoURL: String?, rating: Double, reviewText: String, photos: [String] = [], isVerifiedVisit: Bool = false) {
        self.id = UUID().uuidString
        self.restaurantId = restaurantId
        self.restaurantName = restaurantName
        self.userId = userId
        self.userName = userName
        self.userPhotoURL = userPhotoURL
        self.rating = rating
        self.reviewText = reviewText
        self.photos = photos
        self.createdAt = Date()
        self.updatedAt = Date()
        self.likes = []
        self.isVerifiedVisit = isVerifiedVisit
    }
    
    var likeCount: Int {
        return likes.count
    }
    
    var timeAgo: String {
        return createdAt.timeAgoDisplay()
    }
}

struct RestaurantRating: Codable {
    let restaurantId: String
    let averageRating: Double
    let totalReviews: Int
    let ratingDistribution: [Int: Int] // [stars: count]
    let lastUpdated: Date
    
    init(restaurantId: String) {
        self.restaurantId = restaurantId
        self.averageRating = 0.0
        self.totalReviews = 0
        self.ratingDistribution = [:]
        self.lastUpdated = Date()
    }
    
    func updateRating(newRating: Double, oldRating: Double? = nil) -> RestaurantRating {
        var newTotal = totalReviews
        var newSum = averageRating * Double(totalReviews)
        var newDistribution = ratingDistribution
        
        if let oldRating = oldRating {
            // Update existing review
            newSum = newSum - oldRating + newRating
            let oldStars = Int(oldRating.rounded())
            let newStars = Int(newRating.rounded())
            
            newDistribution[oldStars] = (newDistribution[oldStars] ?? 0) - 1
            newDistribution[newStars] = (newDistribution[newStars] ?? 0) + 1
        } else {
            // New review
            newTotal += 1
            newSum += newRating
            let stars = Int(newRating.rounded())
            newDistribution[stars] = (newDistribution[stars] ?? 0) + 1
        }
        
        let newAverage = newTotal > 0 ? newSum / Double(newTotal) : 0.0
        
        return RestaurantRating(
            restaurantId: restaurantId,
            averageRating: newAverage,
            totalReviews: newTotal,
            ratingDistribution: newDistribution,
            lastUpdated: Date()
        )
    }
}

struct ReviewPhoto: Codable, Identifiable {
    let id: String
    let reviewId: String
    let photoURL: String
    let uploadedAt: Date
    
    init(reviewId: String, photoURL: String) {
        self.id = UUID().uuidString
        self.reviewId = reviewId
        self.photoURL = photoURL
        self.uploadedAt = Date()
    }
}
