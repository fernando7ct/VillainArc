import Foundation
import SwiftData
import FirebaseFirestore
import FirebaseAuth

class DataManager {
    static let shared = DataManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func saveWeightEntry(weight: Double, notes: String, date: Date, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        let newWeightEntry = WeightEntry(id: UUID().uuidString, weight: weight, notes: notes, date: date)
        context.insert(newWeightEntry)
        let weightEntryData: [String: Any] = [
            "id": newWeightEntry.id,
            "weight": weight,
            "notes" : notes,
            "date": date
        ]
        db.collection("users").document(userID).collection("WeightEntries").document(newWeightEntry.id).setData(weightEntryData) { error in
            if let error = error {
                print("Error saving weight entry to Firebase: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteWeightEntry(weightEntry: WeightEntry, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        context.delete(weightEntry)
        db.collection("users").document(userID).collection("WeightEntries").document(weightEntry.id).delete { error in
            if let error = error {
                print("Error deleting weight entry from Firebase: \(error.localizedDescription)")
            }
        }
    }
    
    func syncData(context: ModelContext, userName: String?, completion: @escaping (Bool) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            completion(false)
            return
        }
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                self.downloadUserData(userID: userID, context: context, completion: completion)
            } else {
                self.createUser(userID: userID, userName: userName, context: context, completion: completion)
            }
        }
    }
    
    private func createUser(userID: String, userName: String?, context: ModelContext, completion: @escaping (Bool) -> Void) {
        let newUserName = userName ?? "User"
        let newUser = User(id: userID, name: newUserName, dateJoined: Date())
        context.insert(newUser)
        let userData: [String: Any] = [
            "id": userID,
            "name": newUserName,
            "dateJoined": newUser.dateJoined
        ]
        db.collection("users").document(userID).setData(userData) { error in
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    private func downloadUserData(userID: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                if let data = document.data(), let name = data["name"] as? String, let dateJoined = data["dateJoined"] as? Timestamp {
                    let user = User(id: userID, name: name, dateJoined: dateJoined.dateValue())
                    context.insert(user)
                    self.downloadWeightEntries(userID: userID, context: context, completion: completion)
                }
            } else {
                print("Error downloading user data: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
            }
        }
    }
    
    private func downloadWeightEntries(userID: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userID).collection("WeightEntries").getDocuments { snapshot, error in
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    if let id = document.data()["id"] as? String, let weight = document.data()["weight"] as? Double, let notes = document.data()["notes"] as? String, let date = (document.data()["date"] as? Timestamp)?.dateValue() {
                        let newWeightEntry = WeightEntry(id: id, weight: weight, notes: notes, date: date)
                        context.insert(newWeightEntry)
                    }
                }
                completion(true)
            } else {
                print("Error downloading weight entries: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
            }
        }
    }
}
