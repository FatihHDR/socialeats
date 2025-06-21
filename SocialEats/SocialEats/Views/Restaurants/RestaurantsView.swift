import SwiftUI
import MapKit

struct RestaurantsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var viewModel: RestaurantsViewModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var showingRestaurantDetail = false
    @State private var selectedRestaurant: Restaurant?
    
    init() {
        // We'll need to pass the auth service from the environment
        _viewModel = StateObject(wrappedValue: RestaurantsViewModel(authService: AuthenticationService()))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map View
                Map(coordinateRegion: $region, annotationItems: viewModel.restaurants) { restaurant in
                    MapAnnotation(coordinate: restaurant.coordinate) {
                        RestaurantMapPin(
                            restaurant: restaurant,
                            isSelected: viewModel.isRestaurantSelected(restaurant)
                        ) {
                            selectedRestaurant = restaurant
                            showingRestaurantDetail = true
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                .onAppear {
                    viewModel.requestLocationPermission()
                }
                
                // Selected Restaurant Banner
                if let userSelection = viewModel.userSelectedRestaurant {
                    VStack {
                        Spacer()
                        SelectedRestaurantBanner(
                            selectedRestaurant: userSelection,
                            onClear: {
                                viewModel.clearSelectedRestaurant()
                            }
                        )
                        .padding()
                    }
                }
                
                // Loading Overlay
                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
            .navigationTitle("Restaurants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.refreshLocation) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.orange)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: authService.signOut) {
                        Image(systemName: "person.crop.circle.badge.minus")
                            .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $showingRestaurantDetail) {
                if let restaurant = selectedRestaurant {
                    RestaurantDetailView(
                        restaurant: restaurant,
                        isSelected: viewModel.isRestaurantSelected(restaurant),
                        onSelect: {
                            viewModel.selectRestaurant(restaurant)
                        },
                        onDeselect: {
                            viewModel.clearSelectedRestaurant()
                        }
                    )
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .onAppear {
            // Update the view model with the correct auth service
            viewModel.authService = authService
        }
    }
}

struct RestaurantMapPin: View {
    let restaurant: Restaurant
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                Image(systemName: isSelected ? "fork.knife.circle.fill" : "fork.knife.circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .orange : .red)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 3)
                
                Text(restaurant.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    .shadow(radius: 2)
            }
        }
    }
}

struct SelectedRestaurantBanner: View {
    let selectedRestaurant: SelectedRestaurant
    let onClear: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Selected Restaurant")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(selectedRestaurant.restaurantName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Expires: \(selectedRestaurant.expiresAt, style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onClear) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Finding restaurants...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding(24)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
        }
    }
}

#Preview {
    RestaurantsView()
        .environmentObject(AuthenticationService())
}
