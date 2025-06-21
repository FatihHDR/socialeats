import Foundation
import Combine
import CoreLocation

class RestaurantsViewModel: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    @Published var selectedRestaurant: Restaurant?
    @Published var userSelectedRestaurant: SelectedRestaurant?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let googlePlacesService = GooglePlacesService()
    private let locationService = LocationService()
    private let userService = UserService()
    var authService: AuthenticationService?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthenticationService) {
        self.authService = authService
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind location updates to restaurant search
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.searchNearbyRestaurants(location: location)
            }
            .store(in: &cancellables)
        
        // Bind places service restaurants to our restaurants
        googlePlacesService.$restaurants
            .assign(to: \.restaurants, on: self)
            .store(in: &cancellables)
        
        // Bind loading state
        googlePlacesService.$isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        // Bind error messages
        Publishers.Merge(
            googlePlacesService.$errorMessage.compactMap { $0 },
            locationService.$errorMessage.compactMap { $0 }
        )
        .assign(to: \.errorMessage, on: self)
        .store(in: &cancellables)
        
        // Bind current user's selected restaurant
        authService?.$currentUser
            .compactMap { $0?.selectedRestaurant }
            .assign(to: \.userSelectedRestaurant, on: self)
            .store(in: &cancellables)
    }
    
    func requestLocationPermission() {
        locationService.requestLocationPermission()
    }
    
    func refreshLocation() {
        locationService.getCurrentLocation()
    }
    
    private func searchNearbyRestaurants(location: CLLocation) {
        googlePlacesService.searchNearbyRestaurants(location: location)
    }
    
    func selectRestaurant(_ restaurant: Restaurant) {
        guard let currentUser = authService?.currentUser else { return }
        
        let selectedRestaurant = SelectedRestaurant(
            restaurantId: restaurant.id,
            restaurantName: restaurant.name
        )
        
        userService.updateSelectedRestaurant(
            userId: currentUser.id,
            restaurant: selectedRestaurant
        ) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.userSelectedRestaurant = selectedRestaurant
                    // Update the current user object
                    var updatedUser = currentUser
                    updatedUser.selectedRestaurant = selectedRestaurant
                    self?.authService?.currentUser = updatedUser
                } else {
                    self?.errorMessage = "Failed to select restaurant"
                }
            }
        }
    }
    
    func clearSelectedRestaurant() {
        guard let currentUser = authService?.currentUser else { return }
        
        userService.updateSelectedRestaurant(
            userId: currentUser.id,
            restaurant: nil
        ) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.userSelectedRestaurant = nil
                    // Update the current user object
                    var updatedUser = currentUser
                    updatedUser.selectedRestaurant = nil
                    self?.authService?.currentUser = updatedUser
                } else {
                    self?.errorMessage = "Failed to clear selection"
                }
            }
        }
    }
    
    func isRestaurantSelected(_ restaurant: Restaurant) -> Bool {
        return userSelectedRestaurant?.restaurantId == restaurant.id
    }
    
    func checkSelectionExpiry() {
        if let selectedRestaurant = userSelectedRestaurant, selectedRestaurant.isExpired {
            clearSelectedRestaurant()
        }
    }
}
