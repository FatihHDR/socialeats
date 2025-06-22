import SwiftUI
import PhotosUI

struct UploadPhotoView: View {
    @ObservedObject var viewModel: RestaurantPhotoViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var restaurantsViewModel = RestaurantsViewModel(authService: AuthenticationService())
    
    @State private var selectedImage: UIImage?
    @State private var selectedRestaurant: Restaurant?
    @State private var caption = ""
    @State private var selectedTags: Set<String> = []
    @State private var showingImagePicker = false
    @State private var showingRestaurantPicker = false
    @State private var isUploading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Photo Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Photo")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Button(action: { showingImagePicker = true }) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(12)
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.circle.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.orange.opacity(0.6))
                                    
                                    Text("Tap to select a photo")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                        .strokeBorder(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                                )
                            }
                        }
                    }
                    
                    // Restaurant Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Restaurant")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Button(action: { showingRestaurantPicker = true }) {
                            HStack {
                                if let restaurant = selectedRestaurant {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(restaurant.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        Text(restaurant.address)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                } else {
                                    Text("Select a restaurant")
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Caption
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Caption (Optional)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Share your thoughts about this place...", text: $caption, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    // Tags Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tags")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 120))
                        ], spacing: 12) {
                            ForEach(PhotoTag.predefinedTags) { tag in
                                Button(action: {
                                    if selectedTags.contains(tag.id) {
                                        selectedTags.remove(tag.id)
                                    } else {
                                        selectedTags.insert(tag.id)
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Text(tag.emoji)
                                        Text(tag.name)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedTags.contains(tag.id) 
                                        ? Color(hex: tag.color).opacity(0.2)
                                        : Color.gray.opacity(0.1)
                                    )
                                    .foregroundColor(
                                        selectedTags.contains(tag.id)
                                        ? Color(hex: tag.color)
                                        : .secondary
                                    )
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                selectedTags.contains(tag.id) 
                                                ? Color(hex: tag.color).opacity(0.5)
                                                : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 32)
                    
                    // Upload Button
                    Button(action: uploadPhoto) {
                        HStack {
                            if isUploading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Uploading...")
                            } else {
                                Image(systemName: "cloud.upload.fill")
                                Text("Share Photo")
                            }
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: canUpload ? [Color.orange, Color.orange.opacity(0.8)] : [Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: canUpload ? Color.orange.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(!canUpload || isUploading)
                }
                .padding(24)
            }
            .navigationTitle("Share Photo")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingRestaurantPicker) {
                RestaurantPickerView(
                    restaurants: restaurantsViewModel.restaurants,
                    selectedRestaurant: $selectedRestaurant
                )
            }
            .onAppear {
                restaurantsViewModel.authService = authService
                restaurantsViewModel.requestLocationPermission()
            }
        }
    }
    
    private var canUpload: Bool {
        return selectedImage != nil && selectedRestaurant != nil
    }
    
    private func uploadPhoto() {
        guard let image = selectedImage,
              let restaurant = selectedRestaurant else { return }
        
        isUploading = true
        
        viewModel.uploadPhoto(
            image: image,
            restaurantId: restaurant.id,
            restaurantName: restaurant.name,
            caption: caption.isEmpty ? nil : caption,
            tags: Array(selectedTags)
        ) { success in
            DispatchQueue.main.async {
                self.isUploading = false
                if success {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
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
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    UploadPhotoView(viewModel: RestaurantPhotoViewModel(authService: AuthenticationService()))
        .environmentObject(AuthenticationService())
}
