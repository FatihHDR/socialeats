import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
                    AsyncImage(url: URL(string: authService.currentUser?.photoURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.orange, lineWidth: 3)
                    )
                    
                    VStack(spacing: 4) {
                        Text(authService.currentUser?.displayName ?? "Unknown User")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(authService.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 20)
                
                // Current Selection
                if let selectedRestaurant = authService.currentUser?.selectedRestaurant,
                   !selectedRestaurant.isExpired {
                    VStack(spacing: 8) {
                        Text("Currently Selected")
                            .font(.headline)
                        
                        VStack(spacing: 4) {
                            Text(selectedRestaurant.restaurantName)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                            
                            Text("Expires: \(selectedRestaurant.expiresAt, style: .time)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                } else {
                    VStack(spacing: 8) {
                        Text("No Restaurant Selected")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Go to the Restaurants tab to select where you're dining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Sign Out Button
                Button(action: {
                    authService.signOut()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    UserProfileView()
        .environmentObject(AuthenticationService())
}
