import Foundation
import CoreLocation

class GooglePlacesService: NSObject, ObservableObject {
    private let apiKey = "YOUR_GOOGLE_PLACES_API_KEY" // Replace with your actual API key
    private let baseURL = "https://maps.googleapis.com/maps/api/place"
    
    @Published var restaurants: [Restaurant] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func searchNearbyRestaurants(location: CLLocation, radius: Int = 1500) {
        isLoading = true
        errorMessage = nil
        
        let urlString = "\(baseURL)/nearbysearch/json?location=\(location.coordinate.latitude),\(location.coordinate.longitude)&radius=\(radius)&type=restaurant&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL"
                self.isLoading = false
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    let placesResponse = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
                    
                    if placesResponse.status == "OK" {
                        self?.restaurants = placesResponse.results.map { googlePlace in
                            Restaurant(
                                id: googlePlace.placeId,
                                name: googlePlace.name,
                                address: googlePlace.vicinity,
                                latitude: googlePlace.geometry.location.lat,
                                longitude: googlePlace.geometry.location.lng,
                                rating: googlePlace.rating,
                                priceLevel: googlePlace.priceLevel,
                                photoReference: googlePlace.photos?.first?.photoReference,
                                placeId: googlePlace.placeId,
                                phoneNumber: nil,
                                website: nil,
                                openingHours: nil,
                                types: googlePlace.types
                            )
                        }
                    } else {
                        self?.errorMessage = "Places API error: \(placesResponse.status)"
                    }
                } catch {
                    self?.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func getRestaurantDetails(placeId: String, completion: @escaping (Restaurant?) -> Void) {
        let urlString = "\(baseURL)/details/json?place_id=\(placeId)&fields=name,rating,formatted_phone_number,website,opening_hours,geometry,formatted_address,types,photos&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            // This would need a more detailed response model for place details
            // For now, returning nil as placeholder
            completion(nil)
        }.resume()
    }
    
    func getPhotoURL(photoReference: String, maxWidth: Int = 400) -> String {
        return "\(baseURL)/photo?photoreference=\(photoReference)&maxwidth=\(maxWidth)&key=\(apiKey)"
    }
}
