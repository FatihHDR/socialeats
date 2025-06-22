import Foundation
import Firebase
import FirebaseFirestore
import Combine

class GroupDiningService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let notificationService = NotificationService()
    private let groupDiningsCollection = "groupDinings"
    private let invitationsCollection = "groupDiningInvitations"
    
    func createGroupDining(_ groupDining: GroupDining, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        do {
            try db.collection(groupDiningsCollection).document(groupDining.id).setData(from: groupDining) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                completion(false)
            }
        }
    }
    
    func getGroupDinings(for userId: String, completion: @escaping ([GroupDining]) -> Void) {
        db.collection(groupDiningsCollection)
            .whereField("currentParticipants", arrayContains: userId)
            .order(by: "scheduledDate", descending: false)
            .getDocuments { snapshot, error in
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let groupDinings = documents.compactMap { document in
                    try? document.data(as: GroupDining.self)
                }
                
                DispatchQueue.main.async {
                    completion(groupDinings)
                }
            }
    }
    
    func getUpcomingGroupDinings(completion: @escaping ([GroupDining]) -> Void) {
        let now = Date()
        
        db.collection(groupDiningsCollection)
            .whereField("scheduledDate", isGreaterThan: now)
            .whereField("status", isEqualTo: GroupDiningStatus.active.rawValue)
            .order(by: "scheduledDate", descending: false)
            .limit(to: 20)
            .getDocuments { snapshot, error in
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let groupDinings = documents.compactMap { document in
                    try? document.data(as: GroupDining.self)
                }
                
                DispatchQueue.main.async {
                    completion(groupDinings)
                }
            }
    }
    
    func getGroupDiningsForRestaurant(_ restaurantId: String, completion: @escaping ([GroupDining]) -> Void) {
        let now = Date()
        
        db.collection(groupDiningsCollection)
            .whereField("restaurantId", isEqualTo: restaurantId)
            .whereField("scheduledDate", isGreaterThan: now)
            .whereField("status", isEqualTo: GroupDiningStatus.active.rawValue)
            .order(by: "scheduledDate", descending: false)
            .getDocuments { snapshot, error in
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let groupDinings = documents.compactMap { document in
                    try? document.data(as: GroupDining.self)
                }
                
                DispatchQueue.main.async {
                    completion(groupDinings)
                }
            }
    }
    
    func joinGroupDining(_ groupDiningId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let groupRef = db.collection(groupDiningsCollection).document(groupDiningId)
        
        groupRef.updateData([
            "currentParticipants": FieldValue.arrayUnion([userId]),
            "updatedAt": Timestamp()
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func leaveGroupDining(_ groupDiningId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let groupRef = db.collection(groupDiningsCollection).document(groupDiningId)
        
        groupRef.updateData([
            "currentParticipants": FieldValue.arrayRemove([userId]),
            "updatedAt": Timestamp()
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func sendGroupDiningInvitation(_ invitation: GroupDiningInvitation, completion: @escaping (Bool) -> Void) {
        do {
            try db.collection(invitationsCollection).document(invitation.id).setData(from: invitation) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        completion(false)
                    } else {
                        // Send push notification
                        self?.sendInvitationNotification(invitation)
                        completion(true)
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                completion(false)
            }
        }
    }
    
    func getGroupDiningInvitations(for userId: String, completion: @escaping ([GroupDiningInvitation]) -> Void) {
        db.collection(invitationsCollection)
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: InvitationStatus.pending.rawValue)
            .order(by: "sentAt", descending: true)
            .getDocuments { snapshot, error in
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let invitations = documents.compactMap { document in
                    try? document.data(as: GroupDiningInvitation.self)
                }
                
                DispatchQueue.main.async {
                    completion(invitations)
                }
            }
    }
    
    func respondToInvitation(_ invitationId: String, response: InvitationStatus, completion: @escaping (Bool) -> Void) {
        let invitationRef = db.collection(invitationsCollection).document(invitationId)
        
        invitationRef.updateData([
            "status": response.rawValue
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    // If accepted, add user to group dining
                    if response == .accepted {
                        invitationRef.getDocument { document, error in
                            if let invitation = try? document?.data(as: GroupDiningInvitation.self) {
                                self?.joinGroupDining(invitation.groupDiningId, userId: invitation.toUserId) { success in
                                    completion(success)
                                }
                            } else {
                                completion(true)
                            }
                        }
                    } else {
                        completion(true)
                    }
                }
            }
        }
    }
    
    func cancelGroupDining(_ groupDiningId: String, completion: @escaping (Bool) -> Void) {
        let groupRef = db.collection(groupDiningsCollection).document(groupDiningId)
        
        groupRef.updateData([
            "status": GroupDiningStatus.cancelled.rawValue,
            "updatedAt": Timestamp()
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    private func sendInvitationNotification(_ invitation: GroupDiningInvitation) {
        // Get the invited user's FCM token
        db.collection("users").document(invitation.toUserId).getDocument { [weak self] document, error in
            guard let userData = document?.data(),
                  let fcmToken = userData["fcmToken"] as? String else { return }
            
            self?.notificationService.sendGroupDiningInvitationNotification(
                to: fcmToken,
                fromUserName: invitation.fromUserName,
                groupTitle: invitation.groupTitle,
                restaurantName: invitation.restaurantName,
                scheduledDate: invitation.scheduledDate
            )
        }
    }
}
