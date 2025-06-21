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
                VStack(alignment: .leading, spacing: 24) {
                    // Restaurant Info
                    HStack(spacing: 16) {
                        AsyncImage(url: photoURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        }
                        .frame(width: 80, height: 80)
                        .cornerRadius(12)
                        .clipped()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(restaurant.name)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(restaurant.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Rating Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Rate your experience")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { star in
                                    Button(action: { rating = Double(star) }) {
                                        Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                            .font(.title2)
                                            .foregroundColor(.orange)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(ratingText)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        // Review Text Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Write your review")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            TextEditor(text: $reviewText)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Photos Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Add photos")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Button(action: { showingImagePicker = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "camera")
                                        Text("Add")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(16)
                                }
                            }
                            
                            if !selectedPhotos.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(Array(selectedPhotos.enumerated()), id: \.offset) { index, photo in
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: photo)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 80, height: 80)
                                                    .cornerRadius(8)
                                                    .clipped()
                                                
                                                Button(action: { selectedPhotos.remove(at: index) }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red)
                                                        .background(Color.white)
                                                        .clipShape(Circle())
                                                }
                                                .offset(x: 8, y: -8)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .padding(.horizontal, -20)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("Write Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitReview()
                    }
                    .disabled(reviewText.isEmpty || isSubmitting)
                    .fontWeight(.semibold)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: submitReview) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isSubmitting ? "Submitting..." : "Submit Review")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(reviewText.isEmpty ? Color.gray : Color.orange)
                    .cornerRadius(16)
                }
                .disabled(reviewText.isEmpty || isSubmitting)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .background(Color(.systemBackground))
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
