import SwiftUI

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    let isSelected: Bool
    let onSelect: () -> Void
    let onDeselect: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Restaurant Image
                    AsyncImage(url: photoURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(height: 200)
                    .clipped()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Restaurant Name and Rating
                        VStack(alignment: .leading, spacing: 8) {
                            Text(restaurant.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            HStack {
                                if let rating = restaurant.rating {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text(String(format: "%.1f", rating))
                                            .fontWeight(.semibold)
                                    }
                                }
                                
                                if let priceLevel = restaurant.priceLevel {
                                    Text(String(repeating: "$", count: priceLevel))
                                        .foregroundColor(.green)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        
                        // Address
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Address")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(restaurant.address)
                                .foregroundColor(.secondary)
                        }
                        
                        // Restaurant Types
                        if !restaurant.types.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cuisine Types")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 100))
                                ], spacing: 8) {
                                    ForEach(restaurant.types.prefix(6), id: \.self) { type in
                                        Text(type.capitalized.replacingOccurrences(of: "_", with: " "))
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.orange.opacity(0.1))
                                            .foregroundColor(.orange)
                                            .cornerRadius(16)
                                    }
                                }
                            }
                        }
                        
                        // Contact Information
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contact")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if let phoneNumber = restaurant.phoneNumber {
                                Button(action: {
                                    if let url = URL(string: "tel:\(phoneNumber)") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "phone")
                                        Text(phoneNumber)
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                            
                            if let website = restaurant.website {
                                Button(action: {
                                    if let url = URL(string: website) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "globe")
                                        Text("Website")
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Restaurant Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSelected ? "Deselect" : "Select") {
                        if isSelected {
                            onDeselect()
                        } else {
                            onSelect()
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(isSelected ? .red : .orange)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var photoURL: URL? {
        guard let photoReference = restaurant.photoReference else { return nil }
        return URL(string: "https://maps.googleapis.com/maps/api/place/photo?photoreference=\(photoReference)&maxwidth=400&key=YOUR_API_KEY")
    }
}

#Preview {
    RestaurantDetailView(
        restaurant: Restaurant(
            id: "1",
            name: "Sample Restaurant",
            address: "123 Main St, City, State",
            latitude: 37.7749,
            longitude: -122.4194,
            rating: 4.5,
            priceLevel: 2,
            photoReference: nil,
            placeId: "sample_place_id",
            phoneNumber: "+1234567890",
            website: "https://example.com",
            openingHours: nil,
            types: ["restaurant", "food", "italian"]
        ),
        isSelected: false,
        onSelect: {},
        onDeselect: {}
    )
}
