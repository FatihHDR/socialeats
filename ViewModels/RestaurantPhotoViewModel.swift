import Foundation
import Combine
import UIKit

class RestaurantPhotoViewModel: ObservableObject {
    @Published var photos: [RestaurantPhoto] = []
    @Published var friendsPhotos: [RestaurantPhoto] = []
    @Published var userPhotos: [RestaurantPhoto] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTags: [String] = []
    
    private let photoService = RestaurantPhotoService()
    private let authService: AuthenticationService
    private let userService = UserService()
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthenticationService) {
        self.authService = authService
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind loading state
        photoService.$isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        // Bind error messages
        photoService.$errorMessage
            .compactMap { $0 }
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }
    
    func loadPhotosForRestaurant(_ restaurantId: String) {
        photoService.getPhotosForRestaurant(restaurantId) { [weak self] photos in
            DispatchQueue.main.async {
                self?.photos = photos
            }
        }
    }
    
    func loadFriendsPhotos() {
        guard let currentUser = authService.currentUser else { return }
        
        photoService.getPhotosFromFriends(currentUser.friends) { [weak self] photos in
            DispatchQueue.main.async {
                self?.friendsPhotos = photos
            }
        }
    }
    
    func loadUserPhotos() {
        guard let currentUser = authService.currentUser else { return }
        
        photoService.getUserPhotos(currentUser.id) { [weak self] photos in
            DispatchQueue.main.async {
                self?.userPhotos = photos
            }
        }
    }
    
    func uploadPhoto(
        image: UIImage,
        restaurantId: String,
        restaurantName: String,
        caption: String?,
        tags: [String],
        completion: @escaping (Bool) -> Void
    ) {
        guard let currentUser = authService.currentUser,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(false)
            return
        }
        
        // Check if user is currently at the restaurant for verification
        let isVerified = currentUser.selectedRestaurant?.restaurantId == restaurantId
        
        photoService.uploadPhoto(
            imageData: imageData,
            restaurantId: restaurantId,
            restaurantName: restaurantName,
            userId: currentUser.id,
            userName: currentUser.displayName,
            userPhotoURL: currentUser.photoURL,
            caption: caption,
            tags: tags,
            isVerified: isVerified
        ) { [weak self] success in
            if success {
                self?.loadPhotosForRestaurant(restaurantId)
                self?.loadUserPhotos()
            }
            completion(success)
        }
    }
    
    func likePhoto(_ photo: RestaurantPhoto, completion: @escaping (Bool) -> Void) {
        guard let currentUser = authService.currentUser else {
            completion(false)
            return
        }
        
        photoService.likePhoto(photo.id, userId: currentUser.id) { success in
            // Update local state optimistically
            if success {
                // Refresh photos to get updated like count
                // This could be optimized by updating the local array
            }
            completion(success)
        }
    }
    
    func unlikePhoto(_ photo: RestaurantPhoto, completion: @escaping (Bool) -> Void) {
        guard let currentUser = authService.currentUser else {
            completion(false)
            return
        }
        
        photoService.unlikePhoto(photo.id, userId: currentUser.id) { success in
            // Update local state optimistically
            if success {
                // Refresh photos to get updated like count
                // This could be optimized by updating the local array
            }
            completion(success)
        }
    }
    
    func deletePhoto(_ photo: RestaurantPhoto, completion: @escaping (Bool) -> Void) {
        guard let currentUser = authService.currentUser,
              photo.userId == currentUser.id else {
            completion(false)
            return
        }
        
        photoService.deletePhoto(photo.id) { [weak self] success in
            if success {
                self?.loadPhotosForRestaurant(photo.restaurantId)
                self?.loadUserPhotos()
            }
            completion(success)
        }
    }
    
    func loadPhotosByTag(_ tag: String) {
        photoService.getPhotosByTag(tag) { [weak self] photos in
            DispatchQueue.main.async {
                self?.photos = photos
            }
        }
    }
    
    func loadMostLikedPhotos() {
        photoService.getMostLikedPhotos { [weak self] photos in
            DispatchQueue.main.async {
                self?.photos = photos
            }
        }
    }
    
    func filterPhotosByTags(_ tags: [String]) {
        if tags.isEmpty {
            return
        }
        
        selectedTags = tags
        
        // Filter current photos by selected tags
        let filteredPhotos = photos.filter { photo in
            return tags.allSatisfy { tag in
                photo.tags.contains(tag)
            }
        }
        
        photos = filteredPhotos
    }
    
    func clearFilters() {
        selectedTags = []
    }
    
    func isPhotoLikedByCurrentUser(_ photo: RestaurantPhoto) -> Bool {
        guard let currentUser = authService.currentUser else { return false }
        return photo.likes.contains(currentUser.id)
    }
    
    func canDeletePhoto(_ photo: RestaurantPhoto) -> Bool {
        guard let currentUser = authService.currentUser else { return false }
        return photo.userId == currentUser.id
    }
    
    func getAvailableTags() -> [PhotoTag] {
        return PhotoTag.predefinedTags
    }
    
    func searchPhotos(query: String) {
        // Simple search implementation - can be enhanced
        let lowercaseQuery = query.lowercased()
        
        let filteredPhotos = photos.filter { photo in
            photo.caption?.lowercased().contains(lowercaseQuery) == true ||
            photo.restaurantName.lowercased().contains(lowercaseQuery) ||
            photo.userName.lowercased().contains(lowercaseQuery) ||
            photo.tags.contains { $0.lowercased().contains(lowercaseQuery) }
        }
        
        photos = filteredPhotos
    }
}
