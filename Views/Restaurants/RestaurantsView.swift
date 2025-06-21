import SwiftUI
import MapKit
import CoreLocation

struct RestaurantsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var viewModel: RestaurantsViewModel
    @State private var showingRestaurantDetail = false
    @State private var selectedRestaurant: Restaurant?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    init() {
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
                .ignoresSafeArea()
                
                // Current Selection Banner
                if let selectedRestaurant = viewModel.userSelectedRestaurant {
                    VStack {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("You're going to:")
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
                            
                            Button("Clear") {
                                viewModel.clearSelectedRestaurant()
                            }
                            .foregroundColor(.red)
                            .font(.caption)
                            .fontWeight(.semibold)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
                
                // Loading Indicator
                if viewModel.isLoading {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ProgressView("Finding restaurants...")
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Restaurants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.refreshLocation()
                    }) {
                        Image(systemName: "location.circle")
                            .foregroundColor(.orange)
                    }
                }
            }
            .onAppear {
                viewModel.authService = authService
                viewModel.requestLocationPermission()
                viewModel.checkSelectionExpiry()
            }
            .sheet(item: $selectedRestaurant) { restaurant in
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
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .onChange(of: viewModel.restaurants) { restaurants in
            if let firstRestaurant = restaurants.first {
                region = MKCoordinateRegion(
                    center: firstRestaurant.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
    }
}

struct RestaurantMapPin: View {
    let restaurant: Restaurant
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.green : Color.orange)
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: isSelected ? "checkmark" : "fork.knife")
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .bold))
                }
                
                // Pin tail
                Path { path in
                    path.move(to: CGPoint(x: 15, y: 30))
                    path.addLine(to: CGPoint(x: 10, y: 40))
                    path.addLine(to: CGPoint(x: 20, y: 40))
                    path.closeSubpath()
                }
                .fill(isSelected ? Color.green : Color.orange)
            }
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

#Preview {
    RestaurantsView()
        .environmentObject(AuthenticationService())
}
