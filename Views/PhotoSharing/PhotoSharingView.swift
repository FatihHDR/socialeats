import SwiftUI

struct PhotoSharingView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var viewModel: RestaurantPhotoViewModel
    @State private var selectedTab: PhotoTab = .feed
    @State private var showingCamera = false
    @State private var showingUpload = false
    
    init() {
        _viewModel = StateObject(wrappedValue: RestaurantPhotoViewModel(authService: AuthenticationService()))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Tab Selector
                Picker("Tab", selection: $selectedTab) {
                    Text("Feed").tag(PhotoTab.feed)
                    Text("My Photos").tag(PhotoTab.myPhotos)
                    Text("Explore").tag(PhotoTab.explore)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                switch selectedTab {
                case .feed:
                    PhotoFeedView(viewModel: viewModel)
                case .myPhotos:
                    MyPhotosView(viewModel: viewModel)
                case .explore:
                    ExplorePhotosView(viewModel: viewModel)
                }
            }
            .navigationTitle("Photo Sharing")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingUpload = true }) {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                    }
                }
            }
            .onAppear {
                viewModel.loadFriendsPhotos()
                viewModel.loadUserPhotos()
            }
            .sheet(isPresented: $showingUpload) {
                UploadPhotoView(viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showPhotoSharing)) { _ in
            selectedTab = .feed
        }
    }
}

enum PhotoTab: CaseIterable {
    case feed
    case myPhotos
    case explore
}

struct PhotoFeedView: View {
    @ObservedObject var viewModel: RestaurantPhotoViewModel
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("Loading photos...")
                    .padding()
            } else if viewModel.friendsPhotos.isEmpty {
                EmptyPhotoFeedView()
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.friendsPhotos) { photo in
                        PhotoCard(photo: photo, viewModel: viewModel)
                    }
                }
                .padding()
            }
        }
        .refreshable {
            viewModel.loadFriendsPhotos()
        }
    }
}

struct MyPhotosView: View {
    @ObservedObject var viewModel: RestaurantPhotoViewModel
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("Loading your photos...")
                    .padding()
            } else if viewModel.userPhotos.isEmpty {
                EmptyMyPhotosView()
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.userPhotos) { photo in
                        MyPhotoCard(photo: photo, viewModel: viewModel)
                    }
                }
                .padding()
            }
        }
        .refreshable {
            viewModel.loadUserPhotos()
        }
    }
}

struct ExplorePhotosView: View {
    @ObservedObject var viewModel: RestaurantPhotoViewModel
    @State private var selectedTag: String?
    @State private var searchText = ""
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search photos...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            if !searchText.isEmpty {
                                viewModel.searchPhotos(query: searchText)
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Tag filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button("All") {
                            selectedTag = nil
                            viewModel.loadMostLikedPhotos()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedTag == nil ? Color.orange : Color.gray.opacity(0.1))
                        .foregroundColor(selectedTag == nil ? .white : .primary)
                        .cornerRadius(20)
                        
                        ForEach(viewModel.getAvailableTags()) { tag in
                            Button("\(tag.emoji) \(tag.name)") {
                                selectedTag = tag.id
                                viewModel.loadPhotosByTag(tag.id)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedTag == tag.id ? Color.orange : Color.gray.opacity(0.1))
                            .foregroundColor(selectedTag == tag.id ? .white : .primary)
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Photos grid
                if viewModel.isLoading {
                    ProgressView("Loading photos...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if viewModel.photos.isEmpty {
                    EmptyExploreView()
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.photos) { photo in
                            PhotoCard(photo: photo, viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            viewModel.loadMostLikedPhotos()
        }
    }
}

struct EmptyPhotoFeedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.circle")
                .font(.system(size: 60))
                .foregroundColor(.orange.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No Photos Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("When your friends share photos from restaurants, they'll appear here!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.vertical, 40)
    }
}

struct EmptyMyPhotosView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundColor(.orange.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No Photos Shared")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Start sharing photos from your favorite restaurants to build your collection!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.vertical, 40)
    }
}

struct EmptyExploreView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.orange.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("Nothing to Explore")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Try searching for something or check back later for new photos!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.vertical, 40)
    }
}

#Preview {
    PhotoSharingView()
        .environmentObject(AuthenticationService())
}
