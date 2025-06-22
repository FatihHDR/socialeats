import SwiftUI

struct CreateGroupDiningView: View {
    let onComplete: (Bool) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var restaurantsViewModel = RestaurantsViewModel(authService: AuthenticationService())
    @StateObject private var groupDiningViewModel = GroupDiningViewModel(authService: AuthenticationService())
    
    @State private var selectedRestaurant: Restaurant?
    @State private var title = ""
    @State private var description = ""
    @State private var scheduledDate = Date().addingTimeInterval(3600) // 1 hour from now
    @State private var maxParticipants = 4
    @State private var showingRestaurantPicker = false
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Title")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("e.g., 'Friday Night Dinner'", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Restaurant Selection
                    VStack(alignment: .leading, spacing: 8) {
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
                            .cornerRadius(8)
                        }
                    }
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Tell others what this group dining is about...", text: $description, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    // Date and Time Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date & Time")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        DatePicker("Scheduled Date", selection: $scheduledDate, in: Date()...)
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                    
                    // Max Participants Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Maximum Participants")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Stepper(value: $maxParticipants, in: 2...20) {
                                Text("\(maxParticipants) people")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Spacer(minLength: 32)
                    
                    // Create Button
                    Button(action: createGroupDining) {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "person.3.fill")
                            }
                            Text(isCreating ? "Creating..." : "Create Group Dining")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: canCreate ? [Color.orange, Color.orange.opacity(0.8)] : [Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: canCreate ? Color.orange.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(!canCreate || isCreating)
                }
                .padding(24)
            }
            .navigationTitle("Create Group Dining")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
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
            .alert("Error", isPresented: .constant(groupDiningViewModel.errorMessage != nil)) {
                Button("OK") {
                    groupDiningViewModel.errorMessage = nil
                }
            } message: {
                Text(groupDiningViewModel.errorMessage ?? "")
            }
        }
    }
    
    private var canCreate: Bool {
        return !title.isEmpty && selectedRestaurant != nil && scheduledDate > Date()
    }
    
    private func createGroupDining() {
        guard let restaurant = selectedRestaurant else { return }
        
        isCreating = true
        
        groupDiningViewModel.createGroupDining(
            restaurantId: restaurant.id,
            restaurantName: restaurant.name,
            restaurantAddress: restaurant.address,
            title: title,
            description: description,
            scheduledDate: scheduledDate,
            maxParticipants: maxParticipants
        ) { success in
            DispatchQueue.main.async {
                self.isCreating = false
                self.onComplete(success)
                if success {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct RestaurantPickerView: View {
    let restaurants: [Restaurant]
    @Binding var selectedRestaurant: Restaurant?
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    
    var filteredRestaurants: [Restaurant] {
        if searchText.isEmpty {
            return restaurants
        } else {
            return restaurants.filter { restaurant in
                restaurant.name.localizedCaseInsensitiveContains(searchText) ||
                restaurant.address.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredRestaurants) { restaurant in
                    Button(action: {
                        selectedRestaurant = restaurant
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(restaurant.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(restaurant.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                
                                if let rating = restaurant.rating {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.orange)
                                            .font(.system(size: 12))
                                        Text(String(format: "%.1f", rating))
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            if selectedRestaurant?.id == restaurant.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search restaurants...")
        }
    }
}

#Preview {
    CreateGroupDiningView { _ in }
        .environmentObject(AuthenticationService())
}
