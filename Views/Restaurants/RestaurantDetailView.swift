import SwiftUI
import Firebase

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    let isSelected: Bool
    let onSelect: () -> Void
    let onDeselect: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var reviewsService = ReviewsService()
    @StateObject private var groupDiningViewModel = GroupDiningViewModel(authService: AuthenticationService())
    @StateObject private var photoViewModel = RestaurantPhotoViewModel(authService: AuthenticationService())
    @State private var reviews: [RestaurantReview] = []
    @State private var restaurantRating: RestaurantRating?
    @State private var groupDinings: [GroupDining] = []
    @State private var photos: [RestaurantPhoto] = []
    @State private var showingReviewSheet = false
    @State private var showingCreateGroupSheet = false
    @State private var showingPhotosSheet = false
    @State private var selectedTab: RestaurantDetailTab = .overview
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Tab", selection: $selectedTab) {
                    Text("Overview").tag(RestaurantDetailTab.overview)
                    Text("Reviews").tag(RestaurantDetailTab.reviews)
                    Text("Groups").tag(RestaurantDetailTab.groups)
                    Text("Photos").tag(RestaurantDetailTab.photos)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                ScrollView {
                    switch selectedTab {
                    case .overview:
                        RestaurantOverviewContent(
                            restaurant: restaurant,
                            isSelected: isSelected,
                            onSelect: onSelect,
                            onDeselect: onDeselect,
                            showingReviewSheet: $showingReviewSheet
                        )
                    case .reviews:
                        RestaurantReviewsContent(
                            reviews: reviews,
                            restaurantRating: restaurantRating,
                            showingReviewSheet: $showingReviewSheet
                        )
                    case .groups:
                        RestaurantGroupsContent(
                            groupDinings: groupDinings,
                            restaurant: restaurant,
                            groupDiningViewModel: groupDiningViewModel,
                            showingCreateGroupSheet: $showingCreateGroupSheet
                        )
                    case .photos:
                        RestaurantPhotosContent(
                            photos: photos,
                            restaurant: restaurant,
                            photoViewModel: photoViewModel,
                            showingPhotosSheet: $showingPhotosSheet
                        )
                    }
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
            .sheet(isPresented: $showingCreateGroupSheet) {
                CreateGroupDiningView { success in
                    if success {
                        loadGroupDinings()
                    }
                }
            }
            .sheet(isPresented: $showingPhotosSheet) {
                UploadPhotoView(viewModel: photoViewModel)
            }
            .onAppear {
                loadReviews()
                loadRating()
                loadGroupDinings()
                loadPhotos()
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
    
    private func loadGroupDinings() {
        groupDiningViewModel.getGroupDiningsForRestaurant(restaurant.id) { loadedGroupDinings in
            DispatchQueue.main.async {
                self.groupDinings = loadedGroupDinings
            }
        }
    }
    
    private func loadPhotos() {
        photoViewModel.loadPhotosForRestaurant(restaurant.id)
        // Update photos from view model
        photos = photoViewModel.photos
    }
}

enum RestaurantDetailTab: CaseIterable {
    case overview
    case reviews
    case groups
    case photos
}

struct RestaurantOverviewContent: View {
    let restaurant: Restaurant
    let isSelected: Bool
    let onSelect: () -> Void
    let onDeselect: () -> Void
    @Binding var showingReviewSheet: Bool
    
    var body: some View {
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
                            if let rating = restaurant.rating {
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
            }
            .padding(24)
        }
    }
    
    private var photoURL: URL? {
        guard let photoReference = restaurant.photoReference else { return nil }
        return URL(string: "https://maps.googleapis.com/maps/api/place/photo?photoreference=\(photoReference)&maxwidth=600&key=YOUR_API_KEY")
    }
}

struct RestaurantReviewsContent: View {
    let reviews: [RestaurantReview]
    let restaurantRating: RestaurantRating?
    @Binding var showingReviewSheet: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange.opacity(0.8))
                        .font(.system(size: 18))
                    Text("Reviews")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if !reviews.isEmpty {
                    Text("\(reviews.count) review\(reviews.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            
            if reviews.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange.opacity(0.3))
                    
                    VStack(spacing: 8) {
                        Text("No reviews yet")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Be the first to share your experience!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: { showingReviewSheet = true }) {
                        Text("Write First Review")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(reviews) { review in
                        ReviewRow(review: review)
                    }
                }
            }
        }
        .padding(24)
    }
}

struct RestaurantGroupsContent: View {
    let groupDinings: [GroupDining]
    let restaurant: Restaurant
    @ObservedObject var groupDiningViewModel: GroupDiningViewModel
    @Binding var showingCreateGroupSheet: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.orange.opacity(0.8))
                        .font(.system(size: 18))
                    Text("Group Dining Events")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: { showingCreateGroupSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Create")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            if groupDinings.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.orange.opacity(0.3))
                    
                    VStack(spacing: 8) {
                        Text("No group events")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Create a group dining event and invite your friends!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(groupDinings) { groupDining in
                        GroupDiningCard(
                            groupDining: groupDining,
                            viewModel: groupDiningViewModel,
                            showJoinButton: true
                        )
                    }
                }
            }
        }
        .padding(24)
    }
}

struct RestaurantPhotosContent: View {
    let photos: [RestaurantPhoto]
    let restaurant: Restaurant
    @ObservedObject var photoViewModel: RestaurantPhotoViewModel
    @Binding var showingPhotosSheet: Bool
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.orange.opacity(0.8))
                        .font(.system(size: 18))
                    Text("Photos")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: { showingPhotosSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 16))
                        Text("Add Photo")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            if photos.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 48))
                        .foregroundColor(.orange.opacity(0.3))
                    
                    VStack(spacing: 8) {
                        Text("No photos yet")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Share the first photo of this restaurant!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(photos) { photo in
                        PhotoCard(photo: photo, viewModel: photoViewModel)
                    }
                }
            }
        }
        .padding(24)
    }
}

struct ReviewRow: View {
    let review: RestaurantReview
    @State private var isLiked = false
    @StateObject private var reviewsService = ReviewsService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: review.userPhotoURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.orange.opacity(0.6))
                                .font(.system(size: 16, weight: .medium))
                        )
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(review.userName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if review.isVerifiedVisit {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 12))
                                Text("Verified")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        Text(review.timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 1) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(review.rating.rounded()) ? "star.fill" : "star")
                                .foregroundColor(.orange)
                                .font(.system(size: 14, weight: .medium))
                        }
                        
                        Spacer()
                    }
                }
            }
            
            Text(review.reviewText)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(4)
                .lineSpacing(2)
            
            HStack(spacing: 16) {
                Button(action: toggleLike) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray.opacity(0.7))
                            .font(.system(size: 16, weight: .medium))
                        Text("\(review.likeCount + (isLiked ? 1 : 0))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            // Check if current user has liked this review
            if let currentUserId = Auth.auth().currentUser?.uid {
                isLiked = review.likes.contains(currentUserId)
            }
        }
    }
    
    private func toggleLike() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        if isLiked {
            reviewsService.unlikeReview(review.id, userId: currentUserId) { success in
                if success {
                    isLiked = false
                }
            }
        } else {
            reviewsService.likeReview(review.id, userId: currentUserId) { success in
                if success {
                    isLiked = true
                }
            }
        }
    }
}

struct GroupDiningRow: View {
    let groupDining: GroupDining
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: groupDining.creatorPhotoURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue.opacity(0.6))
                                .font(.system(size: 16, weight: .medium))
                        )
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(groupDining.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text("by \(groupDining.creatorName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(groupDining.participantCount) participants")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text(groupDining.description)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)
                .lineSpacing(2)
            
            HStack(spacing: 16) {
                Button(action: {
                    // Join or leave group dining
                }) {
                    Text(groupDining.isJoined ? "Leave Group" : "Join Group")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(groupDining.isJoined ? Color.red : Color.green)
                        )
                }
                
                Button(action: {
                    // Show group dining details
                }) {
                    Text("View Details")
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

struct RestaurantPhotoRow: View {
    let photo: RestaurantPhoto
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: URL(string: photo.photoURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .cover)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(height: 200)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            Text(photo.caption)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(2)
                .lineSpacing(2)
            
            HStack(spacing: 16) {
                Button(action: {
                    // Like or unlike photo
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .foregroundColor(.red)
                            .font(.system(size: 16, weight: .medium))
                        Text("\(photo.likeCount)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
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
