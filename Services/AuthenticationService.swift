import Foundation
import Firebase
import FirebaseAuth

class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userService = UserService()
    
    init() {
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            if let firebaseUser = firebaseUser {
                self?.loadUserData(for: firebaseUser)
            } else {
                self?.currentUser = nil
                self?.isAuthenticated = false
            }
        }
    }
    
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else if let firebaseUser = result?.user {
                    self?.loadUserData(for: firebaseUser)
                }
            }
        }
    }
    
    func signUp(email: String, password: String, displayName: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else if let firebaseUser = result?.user {
                    let user = User(
                        id: firebaseUser.uid,
                        email: email,
                        displayName: displayName,
                        photoURL: firebaseUser.photoURL?.absoluteString
                    )
                    self?.userService.createUser(user) { success in
                        if success {
                            self?.currentUser = user
                            self?.isAuthenticated = true
                        } else {
                            self?.errorMessage = "Failed to create user profile"
                        }
                    }
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
        } catch let error {
            errorMessage = error.localizedDescription
        }
    }
    
    func resetPassword(email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    // Show success message
                }
            }
        }
    }
    
    private func loadUserData(for firebaseUser: FirebaseAuth.User) {
        userService.getUser(id: firebaseUser.uid) { [weak self] user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.currentUser = user
                    self?.isAuthenticated = true
                } else {
                    // Create user if doesn't exist
                    let newUser = User(
                        id: firebaseUser.uid,
                        email: firebaseUser.email ?? "",
                        displayName: firebaseUser.displayName ?? "Unknown User",
                        photoURL: firebaseUser.photoURL?.absoluteString
                    )
                    self?.userService.createUser(newUser) { success in
                        if success {
                            self?.currentUser = newUser
                            self?.isAuthenticated = true
                        }
                    }
                }
            }
        }
    }
}
