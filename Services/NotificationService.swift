import Foundation
import UserNotifications
import Firebase
import FirebaseMessaging

class NotificationService: NSObject, ObservableObject {
    @Published var hasPermission = false
    @Published var fcmToken: String?
    
    override init() {
        super.init()
        setupNotifications()
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        // Request permission
        requestNotificationPermission()
        
        // Get FCM token
        getFCMToken()
    }
    
    func requestNotificationPermission() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, _ in
                DispatchQueue.main.async {
                    self.hasPermission = granted
                }
                
                if granted {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        )
    }
    
    private func getFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
                DispatchQueue.main.async {
                    self.fcmToken = token
                }
            }
        }
    }
    
    func sendFriendActivityNotification(to userToken: String, friendName: String, restaurantName: String) {
        let notification = PushNotificationData(
            to: userToken,
            title: "Friend Activity",
            body: "\(friendName) is now dining at \(restaurantName)",
            data: [
                "type": "friend_activity",
                "friend_name": friendName,
                "restaurant_name": restaurantName
            ]
        )
        
        sendPushNotification(notification)
    }
      func sendFriendRequestNotification(to userToken: String, fromName: String) {
        let notification = PushNotificationData(
            to: userToken,
            title: "New Friend Request",
            body: "\(fromName) sent you a friend request",
            data: [
                "type": "friend_request",
                "from_name": fromName
            ]
        )
        
        sendPushNotification(notification)
    }
    
    func sendNewReviewNotification(to userToken: String, reviewerName: String, restaurantName: String, rating: Double) {
        let notification = PushNotificationData(
            to: userToken,
            title: "New Restaurant Review",
            body: "\(reviewerName) reviewed \(restaurantName) - \(Int(rating)) stars",
            data: [
                "type": "new_review",
                "reviewer_name": reviewerName,
                "restaurant_name": restaurantName,
                "rating": String(rating)
            ]
        )
        
        sendPushNotification(notification)
    }
    
    func sendReviewLikedNotification(to userToken: String, likerName: String, restaurantName: String) {
        let notification = PushNotificationData(
            to: userToken,
            title: "Review Liked",
            body: "\(likerName) liked your review of \(restaurantName)",
            data: [
                "type": "review_liked",
                "liker_name": likerName,
                "restaurant_name": restaurantName
            ]
        )
        
        sendPushNotification(notification)
    }
    
    func sendGroupDiningInvitationNotification(to userToken: String, fromUserName: String, groupTitle: String, restaurantName: String, scheduledDate: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let notification = PushNotificationData(
            to: userToken,
            title: "Group Dining Invitation",
            body: "\(fromUserName) invited you to \(groupTitle) at \(restaurantName) on \(formatter.string(from: scheduledDate))",
            data: [
                "type": "group_dining_invitation",
                "from_user_name": fromUserName,
                "group_title": groupTitle,
                "restaurant_name": restaurantName,
                "scheduled_date": scheduledDate.ISO8601Format()
            ]
        )
        
        sendPushNotification(notification)
    }
    
    func sendNewPhotoNotification(to userToken: String, userName: String, restaurantName: String) {
        let notification = PushNotificationData(
            to: userToken,
            title: "New Photo Shared",
            body: "\(userName) shared a photo from \(restaurantName)",
            data: [
                "type": "new_photo",
                "user_name": userName,
                "restaurant_name": restaurantName
            ]
        )
        
        sendPushNotification(notification)
    }
    
    func sendGroupDiningReminderNotification(to userToken: String, groupTitle: String, restaurantName: String, scheduledDate: Date) {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let notification = PushNotificationData(
            to: userToken,
            title: "Group Dining Reminder",
            body: "Don't forget about \(groupTitle) at \(restaurantName) at \(formatter.string(from: scheduledDate))",
            data: [
                "type": "group_dining_reminder",
                "group_title": groupTitle,
                "restaurant_name": restaurantName,
                "scheduled_date": scheduledDate.ISO8601Format()
            ]
        )
        
        sendPushNotification(notification)
    }
    
    private func sendPushNotification(_ notification: PushNotificationData) {
        guard let url = URL(string: "https://fcm.googleapis.com/fcm/send") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=YOUR_SERVER_KEY", forHTTPHeaderField: "Authorization")
        
        do {
            let jsonData = try JSONEncoder().encode(notification)
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error sending push notification: \(error)")
                } else {
                    print("Push notification sent successfully")
                }
            }.resume()
        } catch {
            print("Error encoding notification: \(error)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .sound, .banner])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String {
            handleNotificationAction(type: type, userInfo: userInfo)
        }
        
        completionHandler()
    }
      private func handleNotificationAction(type: String, userInfo: [AnyHashable: Any]) {
        switch type {
        case "friend_activity":
            // Navigate to friends tab
            NotificationCenter.default.post(name: .showFriendsTab, object: nil)
        case "friend_request":
            // Navigate to friend requests
            NotificationCenter.default.post(name: .showFriendRequests, object: nil)
        case "new_review", "review_liked":
            // Navigate to restaurants tab or specific restaurant
            if let restaurantName = userInfo["restaurant_name"] as? String {
                NotificationCenter.default.post(name: .showRestaurantReviews, object: restaurantName)
            } else {
                NotificationCenter.default.post(name: .showRestaurantsTab, object: nil)
            }
        case "group_dining_invitation", "group_dining_reminder":
            // Navigate to group dining section
            NotificationCenter.default.post(name: .showGroupDining, object: nil)
        case "new_photo":
            // Navigate to photo sharing section
            NotificationCenter.default.post(name: .showPhotoSharing, object: nil)
        default:
            break
        }
    }
}

// MARK: - MessagingDelegate
extension NotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        
        DispatchQueue.main.async {
            self.fcmToken = fcmToken
        }
        
        // Update user's FCM token in Firestore
        updateUserFCMToken(fcmToken)
    }
    
    private func updateUserFCMToken(_ token: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "fcmToken": token
        ]) { error in
            if let error = error {
                print("Error updating FCM token: \(error)")
            }
        }
    }
}

// MARK: - Data Models
struct PushNotificationData: Codable {
    let to: String
    let notification: NotificationPayload
    let data: [String: String]
    
    init(to: String, title: String, body: String, data: [String: String]) {
        self.to = to
        self.notification = NotificationPayload(title: title, body: body)
        self.data = data
    }
}

struct NotificationPayload: Codable {
    let title: String
    let body: String
}

// MARK: - Notification Names
extension Notification.Name {
    static let showFriendsTab = Notification.Name("showFriendsTab")
    static let showFriendRequests = Notification.Name("showFriendRequests")
    static let showRestaurantsTab = Notification.Name("showRestaurantsTab")
    static let showRestaurantReviews = Notification.Name("showRestaurantReviews")
    static let showGroupDining = Notification.Name("showGroupDining")
    static let showPhotoSharing = Notification.Name("showPhotoSharing")
}
