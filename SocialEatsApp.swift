import SwiftUI
import Firebase

@main
struct SocialEatsApp: App {
    @StateObject private var notificationService = NotificationService()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationService)
        }
    }
}
