import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var isShowingSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    Text("SocialEats")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Discover restaurants with friends")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Authentication Buttons
                VStack(spacing: 16) {
                    NavigationLink(destination: SignInView()) {
                        Text("Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.orange)
                            .cornerRadius(25)
                    }
                    
                    NavigationLink(destination: SignUpView()) {
                        Text("Sign Up")
                            .font(.headline)
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.orange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.orange, lineWidth: 2)
                            )
                            .cornerRadius(25)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Error Message
                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationService())
}
