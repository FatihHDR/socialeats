import SwiftUI

struct WriteReviewView: View {
    let restaurant: Restaurant
    let onReviewSubmitted: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var reviewsService = ReviewsService()
    
    @State private var rating: Double = 5.0
    @State private var reviewText = ""
    @State private var selectedPhotos: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var isSubmitting = false
      var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Restaurant Info with modern design
                    HStack(spacing: 20) {
                        AsyncImage(url: photoURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(.gray.opacity(0.6))
                                )
                        }
                        .frame(width: 88, height: 88)
                        .cornerRadius(16)
                        .clipped()
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(restaurant.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(restaurant.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    VStack(alignment: .leading, spacing: 32) {
                        // Rating Section with enhanced design
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.orange.opacity(0.8))
                                    .font(.system(size: 20))
                                Text("Rate your experience")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    ForEach(1...5, id: \.self) { star in
                                        Button(action: { rating = Double(star) }) {
                                            Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                                .font(.system(size: 32, weight: .medium))
                                                .foregroundColor(star <= Int(rating) ? .orange : .gray.opacity(0.3))
                                                .scaleEffect(star == Int(rating) ? 1.1 : 1.0)
                                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rating)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                
                                Text(ratingText)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                                    .animation(.easeInOut(duration: 0.2), value: rating)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Review Text Section with modern styling
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "text.bubble.fill")
                                    .foregroundColor(.orange.opacity(0.8))
                                    .font(.system(size: 18))
                                Text("Share your thoughts")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            
                            ZStack(alignment: .topLeading) {
                                if reviewText.isEmpty {
                                    Text("Tell others about your experience, the food, service, ambiance...")
                                        .foregroundColor(.secondary.opacity(0.7))
                                        .font(.body)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 16)
                                }
                                
                                TextEditor(text: $reviewText)
                                    .font(.body)
                                    .lineSpacing(4)
                                    .frame(minHeight: 140)
                                    .padding(12)
                                    .background(Color.clear)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.05))
                                    .stroke(reviewText.isEmpty ? Color.gray.opacity(0.2) : Color.orange.opacity(0.4), lineWidth: 1.5)
                            )
                        }
                        
                        // Photos Section with enhanced design
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.orange.opacity(0.8))
                                        .font(.system(size: 18))
                                    Text("Add photos")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                Button(action: { showingImagePicker = true }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 16))
                                        Text("Add Photo")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(20)
                                }
                            }
                            
                            if !selectedPhotos.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(Array(selectedPhotos.enumerated()), id: \.offset) { index, photo in
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: photo)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 88, height: 88)
                                                    .cornerRadius(12)
                                                    .clipped()
                                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                                
                                                Button(action: { selectedPhotos.remove(at: index) }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(.red)
                                                        .background(Color.white)
                                                        .clipShape(Circle())
                                                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                                }
                                                .offset(x: 8, y: -8)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                                .padding(.horizontal, -24)
                            } else {
                                Button(action: { showingImagePicker = true }) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "camera.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.orange.opacity(0.6))
                                        
                                        Text("Add photos to help others")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 100)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.gray.opacity(0.05))
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1.5, style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 120)
                }
                .padding(.top, 8)
            }            .navigationTitle("Write Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: submitReview) {
                    HStack(spacing: 8) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .medium))
                        }
                        Text(isSubmitting ? "Submitting Review..." : "Submit Review")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: reviewText.isEmpty || isSubmitting ? 
                                [Color.gray.opacity(0.6), Color.gray.opacity(0.4)] :
                                [Color.orange, Color.orange.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: reviewText.isEmpty ? .clear : .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(reviewText.isEmpty || isSubmitting)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .background(
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -4)
                        .mask(Rectangle().padding(.top, -20))
                )
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImages: $selectedPhotos)
            }
        }
    }
    
    private var ratingText: String {
        switch Int(rating) {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent"
        default: return ""
        }
    }
    
    private var photoURL: URL? {
        guard let photoReference = restaurant.photoReference else { return nil }
        return URL(string: "https://maps.googleapis.com/maps/api/place/photo?photoreference=\(photoReference)&maxwidth=200&key=YOUR_API_KEY")
    }
    
    private func submitReview() {
        guard let currentUser = authService.currentUser else { return }
        
        isSubmitting = true
        
        // Check if user actually visited this restaurant
        let isVerifiedVisit = currentUser.selectedRestaurant?.restaurantId == restaurant.id
        
        let review = RestaurantReview(
            restaurantId: restaurant.id,
            restaurantName: restaurant.name,
            userId: currentUser.id,
            userName: currentUser.displayName,
            userPhotoURL: currentUser.photoURL,
            rating: rating,
            reviewText: reviewText,
            isVerifiedVisit: isVerifiedVisit
        )
        
        reviewsService.submitReview(review) { success in
            DispatchQueue.main.async {
                self.isSubmitting = false
                
                if success {
                    self.onReviewSubmitted()
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

// Simple Image Picker (you might want to use a more sophisticated one)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImages.append(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    WriteReviewView(
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
            phoneNumber: nil,
            website: nil,
            openingHours: nil,
            types: ["restaurant"]
        ),
        onReviewSubmitted: {}
    )
    .environmentObject(AuthenticationService())
}
