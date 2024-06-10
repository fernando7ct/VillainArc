import Foundation
import SwiftData
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import SwiftUI
import CloudKit

class DataManager {
    @AppStorage("iCloudEnabled") var iCloudEnabled = false
    static let shared = DataManager()
    private let db = Firestore.firestore()
    private let storageRef = Storage.storage().reference()
    
    private init() {
        self.checkICloudAvailability()
    }
    
    func checkICloudAvailability() {
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self.iCloudEnabled = true
                default:
                    self.iCloudEnabled = false
                }
            }
        }
    }
    func saveWeightEntry(weight: Double, notes: String, date: Date, photoData: Data?, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        let newWeightEntry = WeightEntry(id: UUID().uuidString, weight: weight, notes: notes.trimmingCharacters(in: .whitespacesAndNewlines), date: date, photoData: photoData)
        context.insert(newWeightEntry)
        var weightEntryData: [String: Any] = [
            "id": newWeightEntry.id,
            "weight": newWeightEntry.weight,
            "notes" : newWeightEntry.notes,
            "date": newWeightEntry.date,
            "photoURL": ""
        ]
        if let photoData = photoData {
            let storagePath = "images/\(userID)/\(newWeightEntry.id).jpg"
            let imageRef = storageRef.child(storagePath)
            
            imageRef.putData(photoData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading photo: \(error.localizedDescription)")
                    return
                }
                imageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting photo URL: \(error.localizedDescription)")
                        return
                    }
                    guard let photoURL = url else {
                        print("Photo URL is nil")
                        return
                    }
                    weightEntryData["photoURL"] = photoURL.absoluteString
                    self.db.collection("users").document(userID).collection("WeightEntries").document(newWeightEntry.id).setData(weightEntryData) { error in
                        if let error = error {
                            print("Error saving weight entry to Firebase: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } else {
            db.collection("users").document(userID).collection("WeightEntries").document(newWeightEntry.id).setData(weightEntryData) { error in
                if let error = error {
                    print("Error saving weight entry to Firebase: \(error.localizedDescription)")
                }
            }
        }
    }
    func saveWorkout(exercises: [TempExercise], title: String, notes: String, startTime: Date, endTime: Date, isTemplate: Bool, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        let newWorkout = Workout(id: UUID().uuidString, title: title, startTime: startTime, endTime: endTime, notes: notes, template: isTemplate, exercises: [])
        context.insert(newWorkout)
        var workoutData: [String: Any] = [
            "id": newWorkout.id,
            "title": newWorkout.title,
            "startTime": newWorkout.startTime,
            "endTime": newWorkout.endTime,
            "notes": newWorkout.notes,
            "template": newWorkout.template,
            "exercises": []
        ]
        for (exerciseIndex, exercise) in exercises.enumerated() {
            let newExercise = WorkoutExercise(id: UUID().uuidString, tempExercise: exercise, date: Date(), order: exerciseIndex, workout: newWorkout, sets: [])
            context.insert(newExercise)
            var exerciseData: [String: Any] = [
                "id": newExercise.id,
                "name": newExercise.name,
                "category": newExercise.category,
                "notes": newExercise.notes,
                "date": newExercise.date,
                "order": newExercise.order,
                "sets": []
            ]
            for (setIndex, set) in exercise.sets.enumerated() {
                let newSet = ExerciseSet(id: UUID().uuidString, order: setIndex, tempSet: set, exercise: newExercise)
                context.insert(newSet)
                newExercise.sets!.append(newSet)
                let setData: [String: Any] = [
                    "id": newSet.id,
                    "reps": newSet.reps,
                    "weight": newSet.weight,
                    "order": newSet.order,
                    "restMinutes": newSet.restMinutes,
                    "restSeconds": newSet.restSeconds
                ]
                exerciseData["sets"] = (exerciseData["sets"] as? [[String: Any]] ?? []) + [setData]
            }
            newWorkout.exercises!.append(newExercise)
            workoutData["exercises"] = (workoutData["exercises"] as? [[String: Any]] ?? []) + [exerciseData]
        }
        do {
            try context.save()
            print("Workout saved successfully.")
        } catch {
            print("Failed to save workout: \(error.localizedDescription)")
        }
        db.collection("users").document(userID).collection("Workouts").document(newWorkout.id).setData(workoutData) { error in
            if let error = error {
                print("Error saving workout to Firebase: \(error.localizedDescription)")
            }
        }
    }
    func saveWorkoutAsTemplate(workout: Workout, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        let newWorkout = Workout(id: UUID().uuidString, title: workout.title, startTime: Date(), endTime: Date(), notes: workout.notes, template: true, exercises: [])
        context.insert(newWorkout)
        var workoutData: [String: Any] = [
            "id": newWorkout.id,
            "title": newWorkout.title,
            "startTime": newWorkout.startTime,
            "endTime": newWorkout.endTime,
            "notes": newWorkout.notes,
            "template": newWorkout.template,
            "exercises": []
        ]
        for exercise in workout.exercises!.sorted(by: { $0.order < $1.order }) {
            let newExercise = WorkoutExercise(id: UUID().uuidString, exercise: exercise, date: Date(), workout: newWorkout, sets: [])
            context.insert(newExercise)
            var exerciseData: [String: Any] = [
                "id": newExercise.id,
                "name": newExercise.name,
                "category": newExercise.category,
                "notes": newExercise.notes,
                "date": newExercise.date,
                "order": newExercise.order,
                "sets": []
            ]
            for set in exercise.sets!.sorted(by: { $0.order < $1.order }) {
                let newSet = ExerciseSet(id: UUID().uuidString, set: set, exercise: newExercise)
                context.insert(newSet)
                newExercise.sets!.append(newSet)
                let setData: [String: Any] = [
                    "id": newSet.id,
                    "reps": newSet.reps,
                    "weight": newSet.weight,
                    "order": newSet.order,
                    "restMinutes": newSet.restMinutes,
                    "restSeconds": newSet.restSeconds
                ]
                exerciseData["sets"] = (exerciseData["sets"] as? [[String: Any]] ?? []) + [setData]
            }
            newWorkout.exercises!.append(newExercise)
            workoutData["exercises"] = (workoutData["exercises"] as? [[String: Any]] ?? []) + [exerciseData]
        }
        do {
            try context.save()
            print("Workout saved successfully.")
        } catch {
            print("Failed to save workout: \(error.localizedDescription)")
        }
        db.collection("users").document(userID).collection("Workouts").document(newWorkout.id).setData(workoutData) { error in
            if let error = error {
                print("Error saving workout to Firebase: \(error.localizedDescription)")
            }
        }
    }
    func saveHealthSteps(healthSteps: HealthSteps, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        context.insert(healthSteps)
        let healthStepsData: [String: Any] = [
            "id": healthSteps.id,
            "date": healthSteps.date,
            "steps": healthSteps.steps
        ]
        db.collection("users").document(userID).collection("HealthSteps").document(healthSteps.id).setData(healthStepsData) { error in
            if let error = error {
                print("Error saving health steps to Firebase: \(error.localizedDescription)")
            }
        }
    }
    func updateHealthSteps(healthSteps: HealthSteps, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        do {
            try context.save()
            print("Health Steps updated successfully")
        } catch {
            print("Error updating steps: \(error)")
        }
        let healthStepsData: [String: Any] = [
            "id": healthSteps.id,
            "date": healthSteps.date,
            "steps": healthSteps.steps
        ]
        db.collection("users").document(userID).collection("HealthSteps").document(healthSteps.id).updateData(healthStepsData) { error in
            if let error = error {
                print("Error updating health steps in Firebase: \(error.localizedDescription)")
            } else {
                print("Updated steps in Firebase")
            }
        }
    }
    func saveHealthActiveEnergy(activeEnergy: HealthActiveEnergy, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        context.insert(activeEnergy)
        let healthActiveEnergy: [String: Any] = [
            "id": activeEnergy.id,
            "date": activeEnergy.date,
            "activeEnergy": activeEnergy.activeEnergy
        ]
        db.collection("users").document(userID).collection("HealthActiveEnergy").document(activeEnergy.id).setData(healthActiveEnergy) { error in
            if let error = error {
                print("Error saving health active energy to Firebase: \(error.localizedDescription)")
            }
        }
    }
    func updateHealthActiveEnergy(activeEnergy: HealthActiveEnergy, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        do {
            try context.save()
            print("Health active energy updated successfully")
        } catch {
            print("Error updating health active energy: \(error)")
        }
        let healthActiveEnergy: [String: Any] = [
            "id": activeEnergy.id,
            "date": activeEnergy.date,
            "activeEnergy": activeEnergy.activeEnergy
        ]
        db.collection("users").document(userID).collection("HealthActiveEnergy").document(activeEnergy.id).updateData(healthActiveEnergy) { error in
            if let error = error {
                print("Error updating health active energy in Firebase: \(error.localizedDescription)")
            } else {
                print("Updated active energy in Firebase")
            }
        }
    }
    func saveHealthRestingEnergy(restingEnergy: HealthRestingEnergy, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        context.insert(restingEnergy)
        let healthRestingEnergy: [String: Any] = [
            "id": restingEnergy.id,
            "date": restingEnergy.date,
            "restingEnergy": restingEnergy.restingEnergy
        ]
        db.collection("users").document(userID).collection("HealthRestingEnergy").document(restingEnergy.id).setData(healthRestingEnergy) { error in
            if let error = error {
                print("Error saving health resting energy to Firebase: \(error.localizedDescription)")
            }
        }
    }
    func updateHealthRestingEnergy(restingEnergy: HealthRestingEnergy, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        do {
            try context.save()
            print("Health Steps updated successfully")
        } catch {
            print("Error updating steps: \(error)")
        }
        let healthRestingEnergy: [String: Any] = [
            "id": restingEnergy.id,
            "date": restingEnergy.date,
            "restingEnergy": restingEnergy.restingEnergy
        ]
        db.collection("users").document(userID).collection("HealthRestingEnergy").document(restingEnergy.id).updateData(healthRestingEnergy) { error in
            if let error = error {
                print("Error updating health resting energy in Firebase: \(error.localizedDescription)")
            } else {
                print("Updated resting energy in Firebase")
            }
        }
    }
    func deleteWorkout(workout: Workout, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        context.delete(workout)
        db.collection("users").document(userID).collection("Workouts").document(workout.id).delete { error in
            if let error = error {
                print("Error deleting workout from Firebase: \(error.localizedDescription)")
            }
        }
    }
    func deleteWeightEntry(weightEntry: WeightEntry, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        context.delete(weightEntry)
        let storagePath = "images/\(userID)/\(weightEntry.id).jpg"
        let imageRef = storageRef.child(storagePath)
        imageRef.delete { error in
            if let error = error {
                print("Error deleting image from Firebase Storage: \(error.localizedDescription)")
            }
        }
        db.collection("users").document(userID).collection("WeightEntries").document(weightEntry.id).delete { error in
            if let error = error {
                print("Error deleting weight entry from Firebase: \(error.localizedDescription)")
            }
        }
    }
    func syncData(context: ModelContext, userName: String?, completion: @escaping (Bool) -> Void) {
        completion(true)
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            completion(false)
            return
        }
        db.collection("users").document(userID).getDocument { [self] document, error in
            if let document = document, document.exists {
                if !iCloudEnabled {
                    self.downloadUserData(userID: userID, context: context, completion: completion)
                } else {
                    completion(true)
                }
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
                    self.downloadWorkouts(userID: userID, context: context, completion: completion)
                    self.downloadHealthSteps(userID: userID, context: context, completion: completion)
                    self.downloadHealthActiveEnergy(userID: userID, context: context, completion: completion)
                    self.downloadHealthRestingEnergy(userID: userID, context: context, completion: completion)
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
                    if let id = document.data()["id"] as? String,
                       let weight = document.data()["weight"] as? Double,
                       let notes = document.data()["notes"] as? String,
                       let date = (document.data()["date"] as? Timestamp)?.dateValue() {
                        if let photoURLString = document.data()["photoURL"] as? String,
                           let photoURL = URL(string: photoURLString) {
                            self.downloadPhotoData(from: photoURL) { photoData in
                                let newWeightEntry = WeightEntry(id: id, weight: weight, notes: notes, date: date, photoData: photoData)
                                context.insert(newWeightEntry)
                            }
                        } else {
                            let newWeightEntry = WeightEntry(id: id, weight: weight, notes: notes, date: date, photoData: nil)
                            context.insert(newWeightEntry)
                        }
                    }
                }
                completion(true)
            } else {
                print("Error downloading weight entries: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
            }
        }
    }
    private func downloadPhotoData(from url: URL?, completion: @escaping (Data?) -> Void) {
        guard let url = url else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error downloading photo data: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(data)
            }
        }.resume()
    }
    private func downloadWorkouts(userID: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userID).collection("Workouts").getDocuments { snapshot, error in
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    if let id = document.data()["id"] as? String, let title = document.data()["title"] as? String, let startTime = (document.data()["startTime"] as? Timestamp)?.dateValue(), let endTime = (document.data()["endTime"] as? Timestamp)?.dateValue(), let notes = document.data()["notes"] as? String, let template = document.data()["template"] as? Bool, let exercisesData = document.data()["exercises"] as? [[String: Any]] {
                        let newWorkout = Workout(id: id, title: title, startTime: startTime, endTime: endTime, notes: notes, template: template, exercises: [])
                        context.insert(newWorkout)
                        for exerciseData in exercisesData {
                            if let exerciseId = exerciseData["id"] as? String,
                               let name = exerciseData["name"] as? String,
                               let category = exerciseData["category"] as? String,
                               let exerciseNotes = exerciseData["notes"] as? String,
                               let date = (exerciseData["date"] as? Timestamp)?.dateValue(),
                               let order = exerciseData["order"] as? Int,
                               let setsData = exerciseData["sets"] as? [[String: Any]] {
                                let newExercise = WorkoutExercise(id: exerciseId, name: name, category: category, notes: exerciseNotes, date: date, order: order, workout: newWorkout, sets: [])
                                context.insert(newExercise)
                                for setData in setsData {
                                    if let setId = setData["id"] as? String,
                                       let reps = setData["reps"] as? Int,
                                       let weight = setData["weight"] as? Double,
                                       let order = setData["order"] as? Int,
                                       let restMinutes = setData["restMinutes"] as? Int,
                                       let restSeconds = setData["restSeconds"] as? Int {
                                        let newSet = ExerciseSet(id: setId, reps: reps, weight: weight, order: order, restMinutes: restMinutes, restSeconds: restSeconds, exercise: newExercise)
                                        context.insert(newSet)
                                        newExercise.sets!.append(newSet)
                                    }
                                }
                                newWorkout.exercises!.append(newExercise)
                            }
                        }
                    }
                }
                completion(true)
            } else {
                print("Error downloading workouts: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
            }
        }
    }
    private func downloadHealthSteps(userID: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
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
    private func downloadHealthActiveEnergy(userID: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
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
    private func downloadHealthRestingEnergy(userID: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
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
}
