import Foundation
import SwiftData
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import SwiftUI
import MapKit

class DataManager {
    @AppStorage("isSignedIn") var isSignedIn = false
    @AppStorage("nutritionSetup") var nutritionSetup = false
    
    static let shared = DataManager()
    
    let db = Firestore.firestore()
    let storageRef = Storage.storage().reference()
    
    func saveWeightEntry(weightEntry: WeightEntry, context: ModelContext, update: Bool, saveToHealthKit: Bool) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        if update {
            do {
                try context.save()
                print("Weight Entry updated in SwiftData")
            } catch {
                print("Error updating Weight Entry in SwiftData: \(error.localizedDescription)")
            }
        } else {
            context.insert(weightEntry)
            print("Weight Entry saved to SwiftData")
        }
        var weightEntryData: [String: Any] = [
            "id": weightEntry.id,
            "weight": weightEntry.weight,
            "notes" : weightEntry.notes,
            "date": weightEntry.date,
            "photoURL": ""
        ]
        if let photoData = weightEntry.photoData {
            let storagePath = "images/\(userID)/\(weightEntry.id).jpg"
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
                    self.db.collection("users").document(userID).collection("WeightEntries").document(weightEntry.id).setData(weightEntryData)
                }
            }
        } else {
            db.collection("users").document(userID).collection("WeightEntries").document(weightEntry.id).setData(weightEntryData)
            print(update ? "Weight Entry updated in Firebase": "Weight Entry saved to Firebase")
        }
        if saveToHealthKit {
            HealthManager.shared.saveWeightToHealthKit(weight: weightEntry.weight, date: weightEntry.date) { success, error in
                if success {
                    print("Weight Entry saved to HealthKit")
                } else {
                    print("Error saving Weight Entry to HealthKit: \(String(describing: error))")
                }
            }
        }
    }
    func createSampleData(context: ModelContext) {
        let incline = TempExercise(name: "Smith Machine Incline Bench Press", category: "Chest", repRange: "3-7", notes: "", sameRestTimes: false, sets: [
            TempSet(reps: 0, weight: 0, restMinutes: 1, restSeconds: 30),
            TempSet(reps: 0, weight: 0, restMinutes: 2, restSeconds: 00),
            TempSet(reps: 0, weight: 0, restMinutes: 3, restSeconds: 00),
            TempSet(reps: 0, weight: 0, restMinutes: 4, restSeconds: 00),
            TempSet(reps: 0, weight: 0, restMinutes: 0, restSeconds: 00)
        ])
        let machineLaterals = TempExercise(name: "Machine Lateral Raise", category: "Shoulders", repRange: "8-12", notes: "", sameRestTimes: false, sets: [
            TempSet(reps: 0, weight: 0, restMinutes: 2, restSeconds: 0),
            TempSet(reps: 0, weight: 0, restMinutes: 3, restSeconds: 0),
            TempSet(reps: 0, weight: 0, restMinutes: 3, restSeconds: 0),
            TempSet(reps: 0, weight: 0, restMinutes: 0, restSeconds: 0)
        ])
        let inclinePress = TempExercise(name: "Incline Machine Press", category: "Chest", repRange: "8-12", notes: "", sameRestTimes: false, sets: [
            TempSet(reps: 0, weight: 0, restMinutes: 3, restSeconds: 0),
            TempSet(reps: 0, weight: 0, restMinutes: 0, restSeconds: 0)
        ])
        let cableLaterals = TempExercise(name: "Cable Lateral Raise", category: "Shoulders", repRange: "12-15", notes: "", sameRestTimes: false, sets: [
            TempSet(reps: 0, weight: 0, restMinutes: 1, restSeconds: 30),
            TempSet(reps: 0, weight: 0, restMinutes: 0, restSeconds: 0)
        ])
        let benchPress = TempExercise(name: "Bench Press", category: "Chest", repRange: "3-7", notes: "", sameRestTimes: false, sets: [
            TempSet(reps: 0, weight: 0, restMinutes: 3, restSeconds: 0),
            TempSet(reps: 0, weight: 0, restMinutes: 0, restSeconds: 0)
        ])
        saveWorkout(exercises: [incline, machineLaterals, inclinePress, cableLaterals, benchPress], title: "Fernando's Chest & Side Delts Workout", notes: "", startTime: Date(), endTime: Date(), isTemplate: true, context: context)
    }
    func saveWorkout(exercises: [TempExercise], title: String, notes: String, startTime: Date, endTime: Date, isTemplate: Bool, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        let newWorkout = Workout(id: UUID().uuidString, title: title, startTime: startTime, endTime: endTime, notes: notes, template: isTemplate, exercises: [])
        context.insert(newWorkout)
        for (exerciseIndex, exercise) in exercises.enumerated() {
            let newExercise = WorkoutExercise(id: UUID().uuidString, tempExercise: exercise, date: startTime, order: exerciseIndex, workout: newWorkout, sets: [])
            context.insert(newExercise)
            for (setIndex, set) in exercise.sets.enumerated() {
                let newSet = ExerciseSet(id: UUID().uuidString, order: setIndex, tempSet: set, exercise: newExercise)
                context.insert(newSet)
                newExercise.sets.append(newSet)
            }
            newWorkout.exercises.append(newExercise)
        }
        do {
            try context.save()
            print("Workout saved to SwiftData")
        } catch {
            print("Failed to save workout: \(error.localizedDescription)")
        }
        let workoutData = newWorkout.toDictionary()
        db.collection("users").document(userID).collection("Workouts").document(newWorkout.id).setData(workoutData)
        print("Workout saved to Firebase")
    }
    func updateWorkout(exercises: [TempExercise], title: String, notes: String, startTime: Date, endTime: Date, workout: Workout?, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        guard let workout = workout else {
            print("No previous workout passed.")
            return
        }
        workout.title = title
        workout.notes = notes
        workout.startTime = startTime
        workout.endTime = endTime
        for exercise in workout.exercises {
            context.delete(exercise)
        }
        workout.exercises = []
        do {
            try context.save()
            print("Workout data updated, exercises cleared.")
        } catch {
            print("Failed to update workout data, and clearing exercises: \(error.localizedDescription)")
        }
        for (exerciseIndex, exercise) in exercises.enumerated() {
            let newExercise = WorkoutExercise(id: UUID().uuidString, tempExercise: exercise, date: workout.startTime, order: exerciseIndex, workout: workout, sets: [])
            context.insert(newExercise)
            for (setIndex, set) in exercise.sets.enumerated() {
                let newSet = ExerciseSet(id: UUID().uuidString, order: setIndex, tempSet: set, exercise: newExercise)
                context.insert(newSet)
                newExercise.sets.append(newSet)
            }
            workout.exercises.append(newExercise)
        }
        do {
            try context.save()
            print("Updated Workout in SwiftData")
        } catch {
            print("Failed to update workout: \(error.localizedDescription)")
        }
        let workoutData = workout.toDictionary()
        db.collection("users").document(userID).collection("Workouts").document(workout.id).setData(workoutData)
        print("Workout saved to Firebase")
    }
    func saveWorkoutAsTemplate(workout: Workout, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        let newWorkout = Workout(id: UUID().uuidString, title: workout.title, startTime: Date(), endTime: Date(), notes: workout.notes, template: true, exercises: [])
        context.insert(newWorkout)
        for exercise in workout.exercises.sorted(by: { $0.order < $1.order }) {
            let newExercise = WorkoutExercise(id: UUID().uuidString, exercise: exercise, date: Date(), workout: newWorkout, sets: [])
            context.insert(newExercise)
            for set in exercise.sets.sorted(by: { $0.order < $1.order }) {
                let newSet = ExerciseSet(id: UUID().uuidString, set: set, exercise: newExercise)
                context.insert(newSet)
                newExercise.sets.append(newSet)
            }
            newWorkout.exercises.append(newExercise)
        }
        do {
            try context.save()
            print("Workout saved as Template in SwiftData")
        } catch {
            print("Failed to save workout: \(error.localizedDescription)")
        }
        let workoutData = newWorkout.toDictionary()
        db.collection("users").document(userID).collection("Workouts").document(newWorkout.id).setData(workoutData)
        print("Workout saved as Template in SwiftData")
    }
    func deleteWorkout(workout: Workout, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        context.delete(workout)
        print("Workout deleted from SwiftData")
        db.collection("users").document(userID).collection("Workouts").document(workout.id).delete()
        print("Workout deleted from Firebase")
    }
    func deleteWeightEntry(weightEntry: WeightEntry, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        context.delete(weightEntry)
        print("Weight Entry deleted from SwiftData")
        if weightEntry.photoData != nil {
            let storagePath = "images/\(userID)/\(weightEntry.id).jpg"
            let imageRef = storageRef.child(storagePath)
            imageRef.delete { error in
                if let error = error {
                    print("Error deleting image from Firebase Storage: \(error.localizedDescription)")
                }
            }
        }
        db.collection("users").document(userID).collection("WeightEntries").document(weightEntry.id).delete()
        print("Weight Entry deleted from Firebase")
        HealthManager.shared.deleteWeightFromHealthKit(weightEntry: weightEntry) { success, error in
            if success {
                print("Weight Entry deleted from HealthKit")
            } else {
                print("Error deleting Weight Entry from HealthKit: \(String(describing: error))")
            }
        }
    }
    func saveHomeGym(gym: MKMapItem, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        
        let fetch = FetchDescriptor<Gym>()
        guard let gyms = try? context.fetch(fetch) else { return }
        
        if let existingHomeGym = gyms.first(where: { $0.favorite }) {
            existingHomeGym.favorite = false
            do {
                try context.save()
                print("Previous home gym unset in SwiftData")
            } catch {
                print("Error unsetting previous home gym")
            }
            let gymData = existingHomeGym.toDictionary()
            db.collection("users").document(userID).collection("Gyms").document(existingHomeGym.id).setData(gymData)
            print("Previous home gym unset in Firebase")
        }
        if let existingGym = gyms.first(where: { $0.latitude == gym.placemark.coordinate.latitude && $0.longitude == gym.placemark.coordinate.longitude }) {
            existingGym.favorite = true
            do {
                try context.save()
                print("Existing Gym set as home gym in SwiftData")
            } catch {
                print("Error changing existing gym as home gym")
            }
            let gymData = existingGym.toDictionary()
            db.collection("users").document(userID).collection("Gyms").document(existingGym.id).setData(gymData)
            print("Existing gym set as home gym in Firebase")
        } else {
            let newGym = Gym(id: UUID().uuidString, mapItem: gym, favorite: true)
            context.insert(newGym)
            do {
                try context.save()
                print("New home gym saved in SwiftData")
            } catch {
                print("Error saving new home gym")
            }
            let gymData = newGym.toDictionary()
            db.collection("users").document(userID).collection("Gyms").document(newGym.id).setData(gymData)
            print("New home gym saved in Firebase")
        }
    }
    func removeHomeGym(gym: Gym, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        gym.favorite = false
        do {
            try context.save()
            print("Home Gym changed in SwiftData")
        } catch {
            print("Error changing home gym in SwiftData")
        }
        let gymData = gym.toDictionary()
        db.collection("users").document(userID).collection("Gyms").document(gym.id).setData(gymData)
        print("Home Gym changed in Firebase")
    }
    func checkUserDataComplete(completion: @escaping (Bool) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                if let data = document.data(),
                   let _ = data["name"] as? String,
                   let _ = data["dateJoined"] as? Timestamp,
                   let _ = data["birthday"] as? Timestamp,
                   let _ = data["heightFeet"] as? Int,
                   let _ = data["heightInches"] as? Int,
                   let _ = data["sex"] as? String {
                    completion(true)
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
    func fetchUserDateJoined(userID: String, completion: @escaping (Date?) -> Void) {
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                if let data = document.data(),
                   let dateJoined = data["dateJoined"] as? Timestamp {
                    completion(dateJoined.dateValue())
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    func deleteDataAndSignOut(context: ModelContext) {
        do {
            try context.delete(model: WeightEntry.self)
            try context.delete(model: User.self)
            try context.delete(model: Workout.self)
            try context.delete(model: WorkoutExercise.self)
            try context.delete(model: ExerciseSet.self)
            try context.delete(model: HealthSteps.self)
            try context.delete(model: HealthEnergy.self)
            try context.delete(model: NutritionHub.self)
            try context.delete(model: NutritionEntry.self)
            try context.delete(model: NutritionFood.self)
            try context.delete(model: Gym.self)
            try Auth.auth().signOut()
            isSignedIn = false
        } catch {
            print("Error deleting data and/or signing user out: \(error.localizedDescription)")
        }
    }
    func createUser(userID: String, userName: String, dateJoined: Date, birthday: Date, heightFeet: Int, heightInches: Int, sex: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
        let newUser = User(id: userID, name: userName, dateJoined: dateJoined, birthday: birthday, heightFeet: heightFeet, heightInches: heightInches, sex: sex)
        context.insert(newUser)
        let userData = newUser.toDictionary()
        db.collection("users").document(userID).setData(userData) { error in
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
                completion(false)
            } else {
                print("User created successfully")
                self.createSampleData(context: context)
                self.downloadWeightEntries(userID: userID, context: context, completion: completion)
                self.downloadWorkouts(userID: userID, context: context, completion: completion)
                self.downloadHomeGym(userId: userID, context: context, completion: completion)
                self.downloadHealthSteps(userID: userID, context: context, completion: completion)
                self.downloadHealthEnergy(userID: userID, context: context, completion: completion)
                self.downloadNutritionHub(userID: userID, context: context, completion: completion)
                self.downloadNutritionEntries(userID: userID, context: context, completion: completion)
                self.downloadNutritionFoods(userID: userID, context: context, completion: completion)
                completion(true)
            }
        }
    }
    func downloadUserData(userID: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                if let data = document.data(),
                   let name = data["name"] as? String,
                   let dateJoined = data["dateJoined"] as? Timestamp,
                   let birthday = data["birthday"] as? Timestamp,
                   let heightFeet = data["heightFeet"] as? Int,
                   let heightInches = data["heightInches"] as? Int,
                   let sex = data["sex"] as? String {
                    let user = User(id: userID, name: name, dateJoined: dateJoined.dateValue(), birthday: birthday.dateValue(), heightFeet: heightFeet, heightInches: heightInches, sex: sex)
                    context.insert(user)
                    
                    self.downloadWeightEntries(userID: userID, context: context, completion: completion)
                    self.downloadWorkouts(userID: userID, context: context, completion: completion)
                    self.downloadHomeGym(userId: userID, context: context, completion: completion)
                    self.downloadHealthSteps(userID: userID, context: context, completion: completion)
                    self.downloadHealthEnergy(userID: userID, context: context, completion: completion)
                    self.downloadNutritionHub(userID: userID, context: context, completion: completion)
                    self.downloadNutritionEntries(userID: userID, context: context, completion: completion)
                    self.downloadNutritionFoods(userID: userID, context: context, completion: completion)
                    
                    print("User data successfully downloaded")
                    completion(true)
                } else {
                    print("Error parsing user data")
                    completion(false)
                }
            } else {
                print("Error downloading user data: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
            }
        }
    }
    private func downloadHomeGym(userId: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userId).collection("Gyms").getDocuments { snapshot, error in
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    if let id = document.data()["id"] as? String,
                       let name = document.data()["name"] as? String,
                       let address = document.data()["address"] as? String,
                       let latitude = document.data()["latitude"] as? Double,
                       let longitude = document.data()["longitude"] as? Double,
                       let favorite = document.data()["favorite"] as? Bool {
                        let homeGym = Gym(id: id, name: name, address: address, latitude: latitude, longitude: longitude, favorite: favorite)
                        context.insert(homeGym)
                        completion(true)
                    }
                }
            } else {
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
    private func downloadNutritionHub(userID: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userID).collection("Nutrition").document("NutritionHub").getDocument { document, error in
            if let document = document {
                if let data = document.data() {
                    if let id = data["id"] as? String,
                       let goal = data["goal"] as? Double,
                       let proteinGoal = data["proteinGoal"] as? Double,
                       let carbsGoal = data["carbsGoal"] as? Double,
                       let fatGoal = data["fatGoal"] as? Double,
                       let caloriesGoal = data["caloriesGoal"] as? Double,
                       let proteinPercentage = data["proteinPercentage"] as? Double,
                       let carbsPercentage = data["carbsPercentage"] as? Double,
                       let fatPercentage = data["fatPercentage"] as? Double,
                       let activityLevel = data["activityLevel"] as? Double,
                       let mealCategories = data["mealCategories"] as? [String] {
                        let nutritionHub = NutritionHub(id: id, goal: goal, proteinGoal: proteinGoal, carbsGoal: carbsGoal, fatGoal: fatGoal, caloriesGoal: caloriesGoal, proteinPercentage: proteinPercentage, carbsPercentage: carbsPercentage, fatPercentage: fatPercentage, activityLevel: activityLevel, mealCategories: mealCategories)
                        context.insert(nutritionHub)
                        self.nutritionSetup = true
                        completion(true)
                    }
                }
            } else {
                print("Error downloading Nutrition Hub: \(String(describing: error))")
                completion(false)
            }
        }
    }
    private func downloadWorkouts(userID: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userID).collection("Workouts").getDocuments { snapshot, error in
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    if let id = document.data()["id"] as? String,
                       let title = document.data()["title"] as? String,
                       let startTime = (document.data()["startTime"] as? Timestamp)?.dateValue(), let endTime = (document.data()["endTime"] as? Timestamp)?.dateValue(), let notes = document.data()["notes"] as? String, let template = document.data()["template"] as? Bool, let exercisesData = document.data()["exercises"] as? [[String: Any]] {
                        let newWorkout = Workout(id: id, title: title, startTime: startTime, endTime: endTime, notes: notes, template: template, exercises: [])
                        context.insert(newWorkout)
                        for exerciseData in exercisesData {
                            if let exerciseId = exerciseData["id"] as? String,
                               let name = exerciseData["name"] as? String,
                               let category = exerciseData["category"] as? String,
                               let repRange = exerciseData["repRange"] as? String,
                               let exerciseNotes = exerciseData["notes"] as? String,
                               let date = (exerciseData["date"] as? Timestamp)?.dateValue(),
                               let order = exerciseData["order"] as? Int,
                               let setsData = exerciseData["sets"] as? [[String: Any]] {
                                let sameRestTimes = exerciseData["sameRestTimes"] as? Bool ?? false
                                let newExercise = WorkoutExercise(id: exerciseId, name: name, category: category, repRange: repRange, notes: exerciseNotes, date: date, order: order, sameRestTimes: sameRestTimes, workout: newWorkout, sets: [])
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
                                        newExercise.sets.append(newSet)
                                    }
                                }
                                newWorkout.exercises.append(newExercise)
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
}
