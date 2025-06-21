import SwiftUI

struct AddFriendView: View {
    @ObservedObject var viewModel: FriendsViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Search Bar
                VStack(alignment: .leading, spacing: 8) {
                    Text("Search by Email")
                        .font(.headline)
                    
                    TextField("Enter friend's email", text: $viewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal)
                
                // Search Results
                if !viewModel.searchResults.isEmpty {
                    List(viewModel.searchResults) { user in
                        UserSearchRow(user: user) {
                            viewModel.sendFriendRequest(to: user)
                        }
                    }
                } else if !viewModel.searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No users found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Make sure the email is correct")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                } else {
                    VStack(spacing: 24) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 8) {
                            Text("Find Friends")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Search for friends by their email address")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button("Add from Contacts") {
                            viewModel.requestContactsAccess()
                        }
                        .font(.headline)
                        .foregroundColor(.orange)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(40)
                }
                
                Spacer()
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct UserSearchRow: View {
    let user: User
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            AsyncImage(url: URL(string: user.photoURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                
                Text(user.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Add Button
            Button(action: onAdd) {
                HStack(spacing: 4) {
                    Image(systemName: "person.badge.plus")
                    Text("Add")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange)
                .cornerRadius(16)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AddFriendView(viewModel: FriendsViewModel(authService: AuthenticationService()))
}
