import Foundation
import Firebase
import FirebaseFirestore

class UserService: ObservableObject {
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    
    func createUser(_ user: User, completion: @escaping (Bool) -> Void) {
        do {
            let userData = try Firestore.Encoder().encode(user)
            db.collection(usersCollection).document(user.id).setData(userData) { error in
                completion(error == nil)
            }
        } catch {
            completion(false)
        }
    }
    
    func getUser(id: String, completion: @escaping (User?) -> Void) {
        db.collection(usersCollection).document(id).getDocument { document, error in
            if let document = document, document.exists {
                do {
                    let user = try document.data(as: User.self)
                    completion(user)
                } catch {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    func updateUser(_ user: User, completion: @escaping (Bool) -> Void) {
        do {
            let userData = try Firestore.Encoder().encode(user)
            db.collection(usersCollection).document(user.id).setData(userData, merge: true) { error in
                completion(error == nil)
            }
        } catch {
            completion(false)
        }
    }
    
    func updateSelectedRestaurant(userId: String, restaurant: SelectedRestaurant?, completion: @escaping (Bool) -> Void) {
        let data: [String: Any]
        
        if let restaurant = restaurant {
            do {
                data = ["selectedRestaurant": try Firestore.Encoder().encode(restaurant)]
            } catch {
                completion(false)
                return
            }
        } else {
            data = ["selectedRestaurant": FieldValue.delete()]
        }
        
        db.collection(usersCollection).document(userId).updateData(data) { error in
            completion(error == nil)
        }
    }
    
    func addFriend(userId: String, friendId: String, completion: @escaping (Bool) -> Void) {
        let batch = db.batch()
        
        let userRef = db.collection(usersCollection).document(userId)
        let friendRef = db.collection(usersCollection).document(friendId)
        
        batch.updateData(["friends": FieldValue.arrayUnion([friendId])], forDocument: userRef)
        batch.updateData(["friends": FieldValue.arrayUnion([userId])], forDocument: friendRef)
        
        batch.commit { error in
            completion(error == nil)
        }
    }
    
    func removeFriend(userId: String, friendId: String, completion: @escaping (Bool) -> Void) {
        let batch = db.batch()
        
        let userRef = db.collection(usersCollection).document(userId)
        let friendRef = db.collection(usersCollection).document(friendId)
        
        batch.updateData(["friends": FieldValue.arrayRemove([friendId])], forDocument: userRef)
        batch.updateData(["friends": FieldValue.arrayRemove([userId])], forDocument: friendRef)
        
        batch.commit { error in
            completion(error == nil)
        }
    }
    
    func searchUsers(by email: String, completion: @escaping ([User]) -> Void) {
        db.collection(usersCollection)
            .whereField("email", isEqualTo: email)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let users = documents.compactMap { document in
                    try? document.data(as: User.self)
                }
                completion(users)
            }
    }
    
    func getFriends(for user: User, completion: @escaping ([Friend]) -> Void) {
        guard !user.friends.isEmpty else {
            completion([])
            return
        }
        
        db.collection(usersCollection)
            .whereField(FieldPath.documentID(), in: user.friends)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let friends = documents.compactMap { document -> Friend? in
                    guard let userData = try? document.data(as: User.self) else { return nil }
                    return Friend(
                        id: userData.id,
                        displayName: userData.displayName,
                        email: userData.email,
                        photoURL: userData.photoURL,
                        selectedRestaurant: userData.selectedRestaurant,
                        lastSeen: Date() // You might want to track this separately
                    )
                }
                completion(friends)
            }
    }
}
