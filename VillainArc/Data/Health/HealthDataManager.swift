import Foundation
import SwiftData
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
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
        let healthStepsData: [String: Any] = [
            "id": healthSteps.id,
            "date": healthSteps.date,
            "steps": healthSteps.steps
        ]
        db.collection("users").document(userID).collection("HealthSteps").document(healthSteps.id).setData(healthStepsData) { error in
            if let error = error {
                print("Error saving/updating Health Steps to Firebase: \(error.localizedDescription)")
            } else {
                print(update ? "Health Steps updated in Firebase" : "Health Steps saved to Firebase")
            }
        }
    }
    func saveHealthActiveEnergy(activeEnergy: HealthActiveEnergy, context: ModelContext, update: Bool) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        if update {
            do {
                try context.save()
                print("Health Active Energy updated in SwiftData")
            } catch {
                print("Error updating Health Active Energy in SwiftData: \(error.localizedDescription)")
            }
        } else {
            context.insert(activeEnergy)
            print("Health Active Energy saved to SwiftData")
        }
        let healthActiveEnergy: [String: Any] = [
            "id": activeEnergy.id,
            "date": activeEnergy.date,
            "activeEnergy": activeEnergy.activeEnergy
        ]
        db.collection("users").document(userID).collection("HealthActiveEnergy").document(activeEnergy.id).setData(healthActiveEnergy) { error in
            if let error = error {
                print("Error saving/updating Health Active Energy to Firebase: \(error.localizedDescription)")
            } else {
                print(update ? "Health Active Energy updated in Firebase" : "Health Active Energy saved to Firebase")
            }
        }
    }
    func saveHealthRestingEnergy(restingEnergy: HealthRestingEnergy, context: ModelContext, update: Bool) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        if update {
            do {
                try context.save()
                print("Health Resting Energy updated in SwiftData")
            } catch {
                print("Error updating Health Resting Energy in SwiftData: \(error.localizedDescription)")
            }
        } else {
            context.insert(restingEnergy)
            print("Health Resting Energy saved to SwiftData")
        }
        let healthRestingEnergy: [String: Any] = [
            "id": restingEnergy.id,
            "date": restingEnergy.date,
            "restingEnergy": restingEnergy.restingEnergy
        ]
        db.collection("users").document(userID).collection("HealthRestingEnergy").document(restingEnergy.id).setData(healthRestingEnergy) { error in
            if let error = error {
                print("Error saving/updating Health Resting Energy to Firebase: \(error.localizedDescription)")
            } else {
                print(update ? "Health Resting Energy updated in Firebase" : "Health Resting Energy saved to Firebase")
            }
        }
    }
    func saveHealthWalkingRunningDistance(healthDistance: HealthWalkingRunningDistance, context: ModelContext, update: Bool) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        if update {
            do {
                try context.save()
                print("Health Walking Running Distance updated in SwiftData")
            } catch {
                print("Error updating Health Walking Running Distance in SwiftData: \(error.localizedDescription)")
            }
        } else {
            context.insert(healthDistance)
            print("Health Walking Running Distance saved to SwiftData")
        }
        let healthDistanceData: [String: Any] = [
            "id": healthDistance.id,
            "date": healthDistance.date,
            "distance": healthDistance.distance
        ]
        db.collection("users").document(userID).collection("HealthWalkingRunningDistance").document(healthDistance.id).setData(healthDistanceData) { error in
            if let error = error {
                print("Error saving/updating Health Walking Running Distance to Firebase: \(error.localizedDescription)")
            } else {
                print(update ? "Health Walking Running Distance updated in Firebase" : "Health Walking Running Distance saved to Firebase")
            }
        }
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
    func downloadHealthActiveEnergy(userID: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userID).collection("HealthActiveEnergy").getDocuments { snapshot, error in
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    if let id = document.data()["id"] as? String, let date = (document.data()["date"] as? Timestamp)?.dateValue(), let activeEnergy = document.data()["activeEnergy"] as? Double {
                        let newHealthActiveEnergy = HealthActiveEnergy(id: id, date: date, activeEnergy: activeEnergy)
                        context.insert(newHealthActiveEnergy)
                    }
                }
                completion(true)
            } else {
                print("Error downloading health active energy: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
            }
        }
    }
    func downloadHealthRestingEnergy(userID: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userID).collection("HealthRestingEnergy").getDocuments { snapshot, error in
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    if let id = document.data()["id"] as? String, let date = (document.data()["date"] as? Timestamp)?.dateValue(), let restingEnergy = document.data()["restingEnergy"] as? Double {
                        let newHealthRestingEnergy = HealthRestingEnergy(id: id, date: date, restingEnergy: restingEnergy)
                        context.insert(newHealthRestingEnergy)
                    }
                }
                completion(true)
            } else {
                print("Error downloading health resting energy: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
            }
        }
    }
    func downloadHealthWalkingRunningDistance(userID: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userID).collection("HealthWalkingRunningDistance").getDocuments { snapshot, error in
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    if let id = document.data()["id"] as? String, let date = (document.data()["date"] as? Timestamp)?.dateValue(), let distance = document.data()["distance"] as? Double {
                        let newHealthDistance = HealthWalkingRunningDistance(id: id, date: date, distance: distance)
                        context.insert(newHealthDistance)
                    }
                }
                completion(true)
            } else {
                print("Error downloading health walking running distance: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
            }
        }
    }
}
