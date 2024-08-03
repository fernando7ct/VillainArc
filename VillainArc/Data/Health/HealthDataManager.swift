import SwiftData
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

extension DataManager {
    func saveHealthSteps(healthSteps: HealthSteps, context: ModelContext, update: Bool) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        if update {
            do {
                try context.save()
                print("Health Steps updated in SwiftData")
            } catch {
                print("Error updating Health Steps in SwiftData: \(error.localizedDescription)")
            }
        } else {
            context.insert(healthSteps)
            print("Health Steps saved to SwiftData")
        }
        let healthStepsData = healthSteps.toDictionary()
        db.collection("users").document(userID).collection("HealthSteps").document(healthSteps.id).setData(healthStepsData)
        print(update ? "Health Steps updated in Firebase" : "Health Steps saved to Firebase")
    }
    func saveHealthEnergy(energy: HealthEnergy, context: ModelContext, update: Bool) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        if update {
            do {
                try context.save()
                print("Health Energy updated in SwiftData")
            } catch {
                print("Error updating Health Energy in SwiftData: \(error.localizedDescription)")
            }
        } else {
            context.insert(energy)
            print("Health Energy saved to SwiftData")
        }
        let healthEnergy = energy.toDictionary()
        db.collection("users").document(userID).collection("HealthEnergy").document(energy.id).setData(healthEnergy)
        print(update ? "Health Energy updated in Firebase" : "Health Energy saved to Firebase")
    }
    func downloadHealthSteps(userID: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userID).collection("HealthSteps").getDocuments { snapshot, error in
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    if let id = document.data()["id"] as? String, let date = (document.data()["date"] as? Timestamp)?.dateValue(), let steps = document.data()["steps"] as? Double {
                        let newHealthSteps = HealthSteps(id: id, date: date, steps: steps)
                        context.insert(newHealthSteps)
                    }
                }
                completion(true)
            } else {
                print("Error downloading health steps: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
            }
        }
    }
    func downloadHealthEnergy(userID: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userID).collection("HealthEnergy").getDocuments { snapshot, error in
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    if let id = document.data()["id"] as? String, let date = (document.data()["date"] as? Timestamp)?.dateValue(), let activeEnergy = document.data()["activeEnergy"] as? Double, let restingEnergy = document.data()["restingEnergy"] as? Double {
                        let newHealthEnergy = HealthEnergy(id: id, date: date, restingEnergy: restingEnergy, activeEnergy: activeEnergy)
                        context.insert(newHealthEnergy)
                    }
                }
                completion(true)
            } else {
                print("Error downloading health energy: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
            }
        }
    }
}
