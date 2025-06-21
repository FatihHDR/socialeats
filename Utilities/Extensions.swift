import Foundation
import CoreLocation

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    func isWithinLast(minutes: Int) -> Bool {
        let minutesAgo = Calendar.current.date(byAdding: .minute, value: -minutes, to: Date()) ?? Date()
        return self > minutesAgo
    }
}

extension String {
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}

extension CLLocation {
    func distance(from restaurant: Restaurant) -> CLLocationDistance {
        let restaurantLocation = CLLocation(latitude: restaurant.latitude, longitude: restaurant.longitude)
        return self.distance(from: restaurantLocation)
    }
}
