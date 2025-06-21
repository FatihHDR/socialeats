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
                    // Restaurant Image with overlay
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: photoURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 40, weight: .ultraLight))
                                        .foregroundColor(.gray.opacity(0.6))
                                )
                        }
                        .frame(height: 280)
                        .clipped()
                        
                        // Gradient overlay
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 280)
                    }
                    
                    VStack(alignment: .leading, spacing: 32) {
                        // Restaurant Header
                        VStack(alignment: .leading, spacing: 16) {
                            Text(restaurant.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 20) {
                                // Rating with enhanced design
                                Group {
                                    if let rating = restaurantRating {
                                        HStack(spacing: 8) {
                                            HStack(spacing: 1) {
                                                ForEach(1...5, id: \.self) { star in
                                                    Image(systemName: star <= Int(rating.averageRating.rounded()) ? "star.fill" : "star")
                                                        .foregroundColor(.orange)
                                                        .font(.system(size: 14, weight: .medium))
                                                }
                                            }
                                            Text(String(format: "%.1f", rating.averageRating))
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                            Text("(\(rating.totalReviews))")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    } else if let rating = restaurant.rating {
                                        HStack(spacing: 8) {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.orange)
                                                .font(.system(size: 14, weight: .medium))
                                            Text(String(format: "%.1f", rating))
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                            Text("Google")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                // Price Level with modern styling
                                if let priceLevel = restaurant.priceLevel {
                                    HStack(spacing: 2) {
                                        ForEach(0..<4, id: \.self) { index in
                                            Text("$")
                                                .foregroundColor(index < priceLevel ? .green : .gray.opacity(0.3))
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .font(.headline)
                                }
                            }
                        }
                        
                        // Address with modern design
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.orange.opacity(0.8))
                                    .font(.system(size: 16))
                                Text("Location")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            Text(restaurant.address)
                                .foregroundColor(.secondary)
                                .font(.body)
                                .lineLimit(nil)
                                .padding(.leading, 24)
                        }
                        
                        // Action Buttons with enhanced design
                        HStack(spacing: 16) {
                            Button(action: isSelected ? onDeselect : onSelect) {
                                HStack(spacing: 8) {
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle.fill")
                                        .font(.system(size: 18, weight: .medium))
                                    Text(isSelected ? "Selected" : "Select Restaurant")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        colors: isSelected ? [Color.green, Color.green.opacity(0.8)] : [Color.orange, Color.orange.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: (isSelected ? Color.green : Color.orange).opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            
                            Button(action: { showingReviewSheet = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "star.circle.fill")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Write Review")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.orange)
                                .frame(width: 140, height: 52)
                                .background(Color.orange.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.orange.opacity(0.6), lineWidth: 1.5)
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
