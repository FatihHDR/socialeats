import SwiftUI

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    let isSelected: Bool
    let onSelect: () -> Void
    let onDeselect: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var reviewsService = ReviewsService()
    @State private var reviews: [RestaurantReview] = []
    @State private var restaurantRating: RestaurantRating?
    @State private var showingReviewSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Restaurant Image
                    AsyncImage(url: photoURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray.opacity(0.6))
                            )
                    }
                    .frame(height: 240)
                    .clipped()
                    
                    VStack(alignment: .leading, spacing: 24) {
                        // Restaurant Header
                        VStack(alignment: .leading, spacing: 12) {
                            Text(restaurant.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 16) {
                                // Rating
                                if let rating = restaurantRating {
                                    HStack(spacing: 4) {
                                        HStack(spacing: 2) {
                                            ForEach(1...5, id: \.self) { star in
                                                Image(systemName: star <= Int(rating.averageRating.rounded()) ? "star.fill" : "star")
                                                    .foregroundColor(.orange)
                                                    .font(.caption)
                                            }
                                        }
                                        Text(String(format: "%.1f", rating.averageRating))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("(\(rating.totalReviews))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } else if let rating = restaurant.rating {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                        Text(String(format: "%.1f", rating))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("(Google)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // Price Level
                                if let priceLevel = restaurant.priceLevel {
                                    Text(String(repeating: "$", count: priceLevel))
                                        .foregroundColor(.green)
                                        .fontWeight(.medium)
                                        .font(.subheadline)
                                }
                            }
                        }
                        
                        // Address
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Address", systemImage: "location")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(restaurant.address)
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            Button(action: isSelected ? onDeselect : onSelect) {
                                HStack {
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                                    Text(isSelected ? "Selected" : "Select")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(isSelected ? Color.green : Color.orange)
                                .cornerRadius(12)
                            }
                            
                            Button(action: { showingReviewSheet = true }) {
                                HStack {
                                    Image(systemName: "star.circle")
                                    Text("Review")
                                }
                                .font(.headline)
                                .foregroundColor(.orange)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.orange.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange, lineWidth: 1.5)
                                )
                            }
                        }
                        
                        // Reviews Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Reviews")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if !reviews.isEmpty {
                                    Text("\(reviews.count) reviews")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if reviews.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "star.circle")
                                        .font(.system(size: 32))
                                        .foregroundColor(.gray.opacity(0.6))
                                    
                                    Text("No reviews yet")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Be the first to review this restaurant!")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(reviews.prefix(3)) { review in
                                        ReviewRow(review: review)
                                    }
                                    
                                    if reviews.count > 3 {
                                        Button("View All Reviews") {
                                            // Navigate to all reviews
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.8))
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingReviewSheet) {
                WriteReviewView(restaurant: restaurant) {
                    loadReviews()
                }
            }
            .onAppear {
                loadReviews()
                loadRating()
            }
        }
    }
    
    private var photoURL: URL? {
        guard let photoReference = restaurant.photoReference else { return nil }
        return URL(string: "https://maps.googleapis.com/maps/api/place/photo?photoreference=\(photoReference)&maxwidth=600&key=YOUR_API_KEY")
    }
    
    private func loadReviews() {
        reviewsService.getReviews(for: restaurant.id) { loadedReviews in
            self.reviews = loadedReviews
        }
    }
    
    private func loadRating() {
        reviewsService.getRestaurantRating(restaurantId: restaurant.id) { rating in
            self.restaurantRating = rating
        }
    }
}

struct ReviewRow: View {
    let review: RestaurantReview
    @State private var isLiked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: review.userPhotoURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                                .font(.caption)
                        )
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(review.userName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if review.isVerifiedVisit {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        Text(review.timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(review.rating.rounded()) ? "star.fill" : "star")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                }
            }
            
            Text(review.reviewText)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(3)
            
            HStack {
                Button(action: { isLiked.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray)
                        Text("\(review.likeCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
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
