import SwiftUI

struct PhotoCard: View {
    let photo: RestaurantPhoto
    @ObservedObject var viewModel: RestaurantPhotoViewModel
    @State private var isLiked = false
    @State private var showingFullScreen = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Photo with overlay
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: photo.photoURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(height: 180)
                .clipped()
                .cornerRadius(12)
                .onTapGesture {
                    showingFullScreen = true
                }
                
                // Verified badge
                if photo.isVerified {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                        Text("Verified")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .padding(8)
                }
            }
            
            // Photo info
            VStack(alignment: .leading, spacing: 6) {
                // User info
                HStack {
                    AsyncImage(url: URL(string: photo.userPhotoURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12))
                            )
                    }
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                    
                    Text(photo.userName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(photo.timeAgo)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Restaurant name
                Text(photo.restaurantName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .lineLimit(1)
                
                // Caption
                if let caption = photo.caption, !caption.isEmpty {
                    Text(caption)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                // Tags
                if !photo.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(photo.tags, id: \.self) { tagId in
                                if let tag = PhotoTag.predefinedTags.first(where: { $0.id == tagId }) {
                                    Text("\(tag.emoji) \(tag.name)")
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
                
                // Actions
                HStack {
                    Button(action: toggleLike) {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .red : .gray)
                                .font(.system(size: 16))
                            
                            Text("\(photo.likeCount + (isLiked && !viewModel.isPhotoLikedByCurrentUser(photo) ? 1 : 0))")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(12)
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
            isLiked = viewModel.isPhotoLikedByCurrentUser(photo)
        }
        .sheet(isPresented: $showingFullScreen) {
            FullScreenPhotoView(photo: photo, viewModel: viewModel)
        }
    }
    
    private func toggleLike() {
        if isLiked {
            viewModel.unlikePhoto(photo) { success in
                if success {
                    isLiked = false
                }
            }
        } else {
            viewModel.likePhoto(photo) { success in
                if success {
                    isLiked = true
                }
            }
        }
    }
}

struct MyPhotoCard: View {
    let photo: RestaurantPhoto
    @ObservedObject var viewModel: RestaurantPhotoViewModel
    @State private var showingOptions = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: URL(string: photo.photoURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                    )
            }
            .frame(height: 120)
            .clipped()
            .cornerRadius(8)
            
            // Options button
            Button(action: { showingOptions = true }) {
                Image(systemName: "ellipsis.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(8)
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(photo.restaurantName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if photo.likeCount > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 10))
                                Text("\(photo.likeCount)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(8)
                .background(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        )
        .actionSheet(isPresented: $showingOptions) {
            ActionSheet(
                title: Text("Photo Options"),
                buttons: [
                    .destructive(Text("Delete Photo")) {
                        showingDeleteAlert = true
                    },
                    .cancel()
                ]
            )
        }
        .alert("Delete Photo", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                viewModel.deletePhoto(photo) { success in
                    // Photo will be removed from the list automatically
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this photo? This action cannot be undone.")
        }
    }
}

struct FullScreenPhotoView: View {
    let photo: RestaurantPhoto
    @ObservedObject var viewModel: RestaurantPhotoViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var isLiked = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Full size photo
                    AsyncImage(url: URL(string: photo.photoURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                ProgressView()
                            )
                            .aspectRatio(1, contentMode: .fit)
                    }
                    .cornerRadius(12)
                    
                    // Photo details
                    VStack(alignment: .leading, spacing: 16) {
                        // User info
                        HStack {
                            AsyncImage(url: URL(string: photo.userPhotoURL ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.gray)
                                    )
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(photo.userName)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text(photo.timeAgo)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if photo.isVerified {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.blue)
                                    Text("Verified Visit")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        
                        // Restaurant name
                        Text(photo.restaurantName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        // Caption
                        if let caption = photo.caption, !caption.isEmpty {
                            Text(caption)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        
                        // Tags
                        if !photo.tags.isEmpty {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                                ForEach(photo.tags, id: \.self) { tagId in
                                    if let tag = PhotoTag.predefinedTags.first(where: { $0.id == tagId }) {
                                        HStack(spacing: 4) {
                                            Text(tag.emoji)
                                            Text(tag.name)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(hex: tag.color).opacity(0.1))
                                        .foregroundColor(Color(hex: tag.color))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        
                        // Like button
                        Button(action: toggleLike) {
                            HStack {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .foregroundColor(isLiked ? .red : .gray)
                                
                                Text("\(photo.likeCount) like\(photo.likeCount == 1 ? "" : "s")")
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(20)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            isLiked = viewModel.isPhotoLikedByCurrentUser(photo)
        }
    }
    
    private func toggleLike() {
        if isLiked {
            viewModel.unlikePhoto(photo) { success in
                if success {
                    isLiked = false
                }
            }
        } else {
            viewModel.likePhoto(photo) { success in
                if success {
                    isLiked = true
                }
            }
        }
    }
}

// Extension to support hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
