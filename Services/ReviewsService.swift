import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage

class ReviewsService: ObservableObject {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let reviewsCollection = "reviews"
    private let ratingsCollection = "restaurant_ratings"
    
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
        ]) { error in
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
}
