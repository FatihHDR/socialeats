import Foundation
import CoreLocation

struct Restaurant: Codable, Identifiable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let rating: Double?
    let priceLevel: Int?
    let photoReference: String?
    let placeId: String
    let phoneNumber: String?
    let website: String?
    let openingHours: OpeningHours?
    let types: [String]
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
}

struct OpeningHours: Codable {
    let openNow: Bool
    let weekdayText: [String]?
    let periods: [Period]?
}

struct Period: Codable {
    let open: TimeOfDay?
    let close: TimeOfDay?
}

struct TimeOfDay: Codable {
    let day: Int
    let time: String
}

// MARK: - Google Places API Response Models
struct GooglePlacesResponse: Codable {
    let results: [GooglePlace]
    let status: String
    let nextPageToken: String?
}

struct GooglePlace: Codable {
    let placeId: String
    let name: String
    let vicinity: String
    let geometry: Geometry
    let rating: Double?
    let priceLevel: Int?
    let photos: [Photo]?
    let types: [String]
    let openingHours: GoogleOpeningHours?
    
    private enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name, vicinity, geometry, rating, photos, types
        case priceLevel = "price_level"
        case openingHours = "opening_hours"
    }
}

struct Geometry: Codable {
    let location: Location
}

struct Location: Codable {
    let lat: Double
    let lng: Double
}

struct Photo: Codable {
    let photoReference: String
    let height: Int
    let width: Int
    
    private enum CodingKeys: String, CodingKey {
        case photoReference = "photo_reference"
        case height, width
    }
}

struct GoogleOpeningHours: Codable {
    let openNow: Bool
    
    private enum CodingKeys: String, CodingKey {
        case openNow = "open_now"
    }
}
