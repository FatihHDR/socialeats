import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage
import UIKit
import Combine

class RestaurantPhotoService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let notificationService = NotificationService()
    private let photosCollection = "restaurantPhotos"
    
    func uploadPhoto(
        imageData: Data,
        restaurantId: String,
        restaurantName: String,
        userId: String,
        userName: String,
        userPhotoURL: String?,
        caption: String?,
        tags: [String],
        isVerified: Bool = false,
        completion: @escaping (Bool) -> Void
    ) {
        isLoading = true
        errorMessage = nil
        
        let photoId = UUID().uuidString
        let photoRef = storage.reference().child("restaurant_photos/\(restaurantId)/\(photoId).jpg")
        
        // Upload image to Firebase Storage
        photoRef.putData(imageData, metadata: nil) { [weak self] metadata, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                }
                return
            }
            
            // Get download URL
            photoRef.downloadURL { url, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        self?.errorMessage = error.localizedDescription
                        completion(false)
                    }
                    return
                }
                
                guard let photoURL = url?.absoluteString else {
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        self?.errorMessage = "Failed to get photo URL"
                        completion(false)
                    }
                    return
                }
                
                // Create RestaurantPhoto object
                let photo = RestaurantPhoto(
                    restaurantId: restaurantId,
                    restaurantName: restaurantName,
                    userId: userId,
                    userName: userName,
                    userPhotoURL: userPhotoURL,
                    photoURL: photoURL,
                    caption: caption,
                    tags: tags,
                    isVerified: isVerified
                )
                
                // Save to Firestore
                self?.savePhotoToFirestore(photo) { success in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        completion(success)
                    }
                }
            }
        }
    }
    
    private func savePhotoToFirestore(_ photo: RestaurantPhoto, completion: @escaping (Bool) -> Void) {
        do {
            try db.collection(photosCollection).document(photo.id).setData(from: photo) { [weak self] error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    // Notify friends about new photo
                    self?.notifyFriendsAboutNewPhoto(photo)
                    completion(true)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            completion(false)
        }
    }
    
    func getPhotosForRestaurant(_ restaurantId: String, completion: @escaping ([RestaurantPhoto]) -> Void) {
        db.collection(photosCollection)
            .whereField("restaurantId", isEqualTo: restaurantId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let photos = documents.compactMap { document in
                    try? document.data(as: RestaurantPhoto.self)
                }
                
                DispatchQueue.main.async {
                    completion(photos)
                }
            }
    }
    
    func getPhotosFromFriends(_ userIds: [String], completion: @escaping ([RestaurantPhoto]) -> Void) {
        guard !userIds.isEmpty else {
            completion([])
            return
        }
        
        db.collection(photosCollection)
            .whereField("userId", in: userIds)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments { snapshot, error in
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let photos = documents.compactMap { document in
                    try? document.data(as: RestaurantPhoto.self)
                }
                
                DispatchQueue.main.async {
                    completion(photos)
                }
            }
    }
    
    func getUserPhotos(_ userId: String, completion: @escaping ([RestaurantPhoto]) -> Void) {
        db.collection(photosCollection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let photos = documents.compactMap { document in
                    try? document.data(as: RestaurantPhoto.self)
                }
                
                DispatchQueue.main.async {
                    completion(photos)
                }
            }
    }
    
    func likePhoto(_ photoId: String, userId: String, completion: @escaping (Bool) -> Void) {
        db.collection(photosCollection).document(photoId).updateData([
            "likes": FieldValue.arrayUnion([userId]),
            "updatedAt": Timestamp()
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func unlikePhoto(_ photoId: String, userId: String, completion: @escaping (Bool) -> Void) {
        db.collection(photosCollection).document(photoId).updateData([
            "likes": FieldValue.arrayRemove([userId]),
            "updatedAt": Timestamp()
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func deletePhoto(_ photoId: String, completion: @escaping (Bool) -> Void) {
        db.collection(photosCollection).document(photoId).delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func getPhotosByTag(_ tag: String, completion: @escaping ([RestaurantPhoto]) -> Void) {
        db.collection(photosCollection)
            .whereField("tags", arrayContains: tag)
            .order(by: "createdAt", descending: true)
            .limit(to: 30)
            .getDocuments { snapshot, error in
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let photos = documents.compactMap { document in
                    try? document.data(as: RestaurantPhoto.self)
                }
                
                DispatchQueue.main.async {
                    completion(photos)
                }
            }
    }
    
    func getMostLikedPhotos(completion: @escaping ([RestaurantPhoto]) -> Void) {
        db.collection(photosCollection)
            .order(by: "likes", descending: true)
            .limit(to: 20)
            .getDocuments { snapshot, error in
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let photos = documents.compactMap { document in
                    try? document.data(as: RestaurantPhoto.self)
                }
                
                DispatchQueue.main.async {
                    completion(photos)
                }
            }
    }
    
    private func notifyFriendsAboutNewPhoto(_ photo: RestaurantPhoto) {
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
                    self?.notificationService.sendNewPhotoNotification(
                        to: token,
                        userName: photo.userName,
                        restaurantName: photo.restaurantName
                    )
                }
            }
        }
    }
}
