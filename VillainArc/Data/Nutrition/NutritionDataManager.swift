import Foundation
import SwiftData
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import SwiftUI

extension DataManager {
    func createNutritionHub(goal: Double, proteinGoal: Double, carbsGoal: Double, fatGoal: Double, caloriesGoal: Double, proteinPercentage: Double, carbsPercentage: Double, fatPercentage: Double, activityLevel: Double, mealCategories: [String], context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        let nutritionHub = NutritionHub(id: UUID().uuidString, goal: goal, proteinGoal: proteinGoal, carbsGoal: carbsGoal, fatGoal: fatGoal, caloriesGoal: caloriesGoal, proteinPercentage: proteinPercentage, carbsPercentage: carbsPercentage, fatPercentage: fatPercentage, activityLevel: activityLevel, mealCategories: mealCategories)
        context.insert(nutritionHub)
        print("Nutrition Hub saved to SwiftData")
        let nutritionData: [String: Any] = [
            "id": nutritionHub.id,
            "goal": nutritionHub.goal,
            "proteinGoal": nutritionHub.proteinGoal,
            "carbsGoal": nutritionHub.carbsGoal,
            "fatGoal": nutritionHub.fatGoal,
            "caloriesGoal": nutritionHub.caloriesGoal,
            "proteinPercentage": nutritionHub.proteinPercentage,
            "carbsPercentage": nutritionHub.carbsPercentage,
            "fatPercentage": nutritionHub.fatPercentage,
            "activityLevel": nutritionHub.activityLevel,
            "mealCategories": nutritionHub.mealCategories
        ]
        db.collection("users").document(userID).collection("Nutrition").document("NutritionHub").setData(nutritionData) { error in
            if let error = error {
                print("Error saving Nutrition Hub to Firebase: \(error.localizedDescription)")
            } else {
                print("Nutrition Hub saved to Firebase")
            }
        }
        self.createNutritionEntry(context: context)
    }
    func nutritionEntryToday(context: ModelContext, completion: @escaping (Bool) -> Void) {
        let fetchDescriptor = FetchDescriptor<NutritionEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let entries = try? context.fetch(fetchDescriptor)
        guard let entries = entries, let todaysEntry = entries.first else {
            completion(false)
            return
        }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if today == todaysEntry.date {
            completion(true)
        } else {
            completion(false)
        }
    }
    func createNutritionEntry(context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        let fetchDescriptor = FetchDescriptor<NutritionHub>()
        let hubs = try! context.fetch(fetchDescriptor)
        let hub = hubs.first!
        let today = Calendar.current.startOfDay(for: Date())
        let nutritionEntry = NutritionEntry(id: UUID().uuidString, date: today, proteinGoal: hub.proteinGoal, carbsGoal: hub.carbsGoal, fatGoal: hub.fatGoal, caloriesGoal: hub.caloriesGoal, proteinConsumed: 0, carbsConsumed: 0, fatConsumed: 0, caloriesConsumed: 0, mealCategories: hub.mealCategories, notes: "", foods: [])
        context.insert(nutritionEntry)
        print("Nutrition Entry saved to SwiftData")
        let entryData: [String: Any] = [
            "id": nutritionEntry.id,
            "date": nutritionEntry.date,
            "proteinGoal": nutritionEntry.proteinGoal,
            "carbsGoal": nutritionEntry.carbsGoal,
            "fatGoal": nutritionEntry.fatGoal,
            "caloriesGoal": nutritionEntry.caloriesGoal,
            "proteinConsumed": nutritionEntry.proteinConsumed,
            "carbsConsumed": nutritionEntry.carbsConsumed,
            "fatConsumed": nutritionEntry.fatConsumed,
            "caloriesConsumed": nutritionEntry.caloriesConsumed,
            "mealCategories": nutritionEntry.mealCategories,
            "notes": nutritionEntry.notes,
            "foods": []
        ]
        db.collection("users").document(userID).collection("Nutrition").document("NutritionHub").collection("NutritionEntries").document(nutritionEntry.id).setData(entryData) { error in
            if let error = error {
                print("Error saving Nutrition Entry to Firebase: \(error.localizedDescription)")
            } else {
                print("Nutrition Entry saved to Firebase")
            }
        }
    }
    func downloadNutritionEntries(userID: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userID).collection("Nutrition").document("NutritionHub").collection("NutritionEntries").getDocuments { snapshot, error in
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    if let id = document.data()["id"] as? String,
                       let date = (document.data()["date"] as? Timestamp)?.dateValue(),
                       let proteinGoal = document.data()["proteinGoal"] as? Double,
                       let carbsGoal = document.data()["carbsGoal"] as? Double,
                       let fatGoal = document.data()["fatGoal"] as? Double,
                       let caloriesGoal = document.data()["caloriesGoal"] as? Double,
                       let proteinConsumed = document.data()["proteinConsumed"] as? Double,
                       let carbsConsumed = document.data()["carbsConsumed"] as? Double,
                       let fatConsumed = document.data()["fatConsumed"] as? Double,
                       let caloriesConsumed = document.data()["caloriesConsumed"] as? Double,
                       let mealCategories = document.data()["mealCategories"] as? [String],
                       let notes = document.data()["notes"] as? String,
                       let foodData = document.data()["foods"] as? [[String: Any]] {
                        let nutritionEntry = NutritionEntry(id: id, date: date, proteinGoal: proteinGoal, carbsGoal: carbsGoal, fatGoal: fatGoal, caloriesGoal: caloriesGoal, proteinConsumed: proteinConsumed, carbsConsumed: carbsConsumed, fatConsumed: fatConsumed, caloriesConsumed: caloriesConsumed, mealCategories: mealCategories, notes: notes, foods: [])
                        context.insert(nutritionEntry)
                        for foodData in foodData {
                            if let id = foodData["id"] as? String, let name = foodData["name"] as? String, let brand = foodData["brand"] as? String, let servingSizeDigit = foodData["servingSizeDigit"] as? Double, let servingSizeUnit = foodData["servingSizeUnit"] as? String, let servingsCount = foodData["servingsCount"] as? Double, let date = (foodData["date"] as? Timestamp)?.dateValue(), let mealCategory = foodData["mealCategory"] as? String, let protein = foodData["protein"] as? Double, let carbs = foodData["carbs"] as? Double, let fat = foodData["fat"] as? Double, let calories = foodData["calories"] as? Double {
                                let newFood = NutritionFood(id: id, name: name, brand: brand, servingSizeDigit: servingSizeDigit, servingSizeUnit: servingSizeUnit, servingsCount: servingsCount, date: date, mealCategory: mealCategory, protein: protein, carbs: carbs, fat: fat, calories: calories)
                                nutritionEntry.foods!.append(newFood)
                            }
                        }
                    }
                }
                completion(true)
            } else {
                print("Error downloading Nutrition Entries: \(String(describing: error))")
                completion(false)
            }
        }
    }

}
