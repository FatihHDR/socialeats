import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage

class ReviewsService: ObservableObject {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let reviewsCollection = "reviews"
    private let ratingsCollection = "restaurant_ratings"
    private let notificationService = NotificationService()
    
    @Published var reviews: [RestaurantReview] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func submitReview(_ review: RestaurantReview, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        do {
            let reviewData = try Firestore.Encoder().encode(review)
            
            db.collection(reviewsCollection).document(review.id).setData(reviewData) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                      if let error = error {
                        self?.errorMessage = error.localizedDescription
                        completion(false)
                    } else {
                        // Update restaurant rating
                        self?.updateRestaurantRating(restaurantId: review.restaurantId, newRating: review.rating)
                        
                        // Send notification to friends about new review
                        self?.notifyFriendsAboutNewReview(review)
                        
                        completion(true)
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                completion(false)
            }
        }
    }
    
    func getReviews(for restaurantId: String, completion: @escaping ([RestaurantReview]) -> Void) {
        db.collection(reviewsCollection)
            .whereField("restaurantId", isEqualTo: restaurantId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let reviews = documents.compactMap { document in
                    try? document.data(as: RestaurantReview.self)
                }
                
                DispatchQueue.main.async {
                    completion(reviews)
                }
            }
    }
    
    func getUserReviews(userId: String, completion: @escaping ([RestaurantReview]) -> Void) {
        db.collection(reviewsCollection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let reviews = documents.compactMap { document in
                    try? document.data(as: RestaurantReview.self)
                }
                
                DispatchQueue.main.async {
                    completion(reviews)
                }
            }
    }
      func likeReview(_ reviewId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let reviewRef = db.collection(reviewsCollection).document(reviewId)
        
        reviewRef.updateData([
            "likes": FieldValue.arrayUnion([userId])
        ]) { [weak self] error in
            if error == nil {
                // Send notification to review author
                self?.notifyReviewAuthorAboutLike(reviewId: reviewId, likerId: userId)
            }
            completion(error == nil)
        }
    }
    
    func unlikeReview(_ reviewId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let reviewRef = db.collection(reviewsCollection).document(reviewId)
        
        reviewRef.updateData([
            "likes": FieldValue.arrayRemove([userId])
        ]) { error in
            completion(error == nil)
        }
    }
    
    func uploadReviewPhoto(_ imageData: Data, reviewId: String, completion: @escaping (String?) -> Void) {
        let photoRef = storage.reference().child("review_photos/\(reviewId)/\(UUID().uuidString).jpg")
        
        photoRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading photo: \(error)")
                completion(nil)
                return
            }
            
            photoRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error)")
                    completion(nil)
                } else {
                    completion(url?.absoluteString)
                }
            }
        }
    }
    
    private func updateRestaurantRating(restaurantId: String, newRating: Double, oldRating: Double? = nil) {
        let ratingRef = db.collection(ratingsCollection).document(restaurantId)
        
        ratingRef.getDocument { document, error in
            var restaurantRating: RestaurantRating
            
            if let document = document, document.exists,
               let existingRating = try? document.data(as: RestaurantRating.self) {
                restaurantRating = existingRating.updateRating(newRating: newRating, oldRating: oldRating)
            } else {
                restaurantRating = RestaurantRating(restaurantId: restaurantId).updateRating(newRating: newRating)
            }
            
            do {
                let ratingData = try Firestore.Encoder().encode(restaurantRating)
                ratingRef.setData(ratingData)
            } catch {
                print("Error updating restaurant rating: \(error)")
            }
        }
    }
      func getRestaurantRating(restaurantId: String, completion: @escaping (RestaurantRating?) -> Void) {
        db.collection(ratingsCollection).document(restaurantId).getDocument { document, error in
            if let document = document, document.exists {
                let rating = try? document.data(as: RestaurantRating.self)
                completion(rating)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Notification Methods
    
    private func notifyFriendsAboutNewReview(_ review: RestaurantReview) {
        // Get user's friends
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(currentUserId).getDocument { [weak self] document, error in
            guard let userData = document?.data(),
                  let friends = userData["friends"] as? [String] else { return }
            
            // Get FCM tokens for friends
            let group = DispatchGroup()
            var friendTokens: [String] = []
            
            for friendId in friends {
                group.enter()
                self?.db.collection("users").document(friendId).getDocument { document, error in
                    if let userData = document?.data(),
                       let fcmToken = userData["fcmToken"] as? String {
                        friendTokens.append(fcmToken)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                // Send notifications to all friends
                for token in friendTokens {
                    self?.notificationService.sendNewReviewNotification(
                        to: token,
                        reviewerName: review.userName,
                        restaurantName: review.restaurantName,
                        rating: review.rating
                    )
                }
            }
        }
    }
    
    private func notifyReviewAuthorAboutLike(reviewId: String, likerId: String) {
        // Get review details
        db.collection(reviewsCollection).document(reviewId).getDocument { [weak self] document, error in
            guard let reviewData = document?.data(),
                  let review = try? document?.data(as: RestaurantReview.self),
                  review.userId != likerId else { return }
            
            // Get liker's name
            self?.db.collection("users").document(likerId).getDocument { likerDoc, error in
                guard let likerData = likerDoc?.data(),
                      let likerName = likerData["name"] as? String else { return }
                
                // Get review author's FCM token
                self?.db.collection("users").document(review.userId).getDocument { authorDoc, error in
                    guard let authorData = authorDoc?.data(),
                          let fcmToken = authorData["fcmToken"] as? String else { return }
                    
                    self?.notificationService.sendReviewLikedNotification(
                        to: fcmToken,
                        likerName: likerName,
                        restaurantName: review.restaurantName
                    )
                }
            }
        }
    }
}
