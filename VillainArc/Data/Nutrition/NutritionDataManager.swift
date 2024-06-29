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
        db.collection("users").document(userID).collection("Nutrition").document("NutritionHub").setData(nutritionData)
        print("Nutrition Hub saved to Firebase")
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
        db.collection("users").document(userID).collection("Nutrition").document("NutritionHub").collection("NutritionEntries").document(nutritionEntry.id).setData(entryData)
        print("Nutrition Entry saved to Firebase")
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
                       let foodDataArray = document.data()["foods"] as? [[String: Any]] {
                        let nutritionEntry = NutritionEntry(id: id, date: date, proteinGoal: proteinGoal, carbsGoal: carbsGoal, fatGoal: fatGoal, caloriesGoal: caloriesGoal, proteinConsumed: proteinConsumed, carbsConsumed: carbsConsumed, fatConsumed: fatConsumed, caloriesConsumed: caloriesConsumed, mealCategories: mealCategories, notes: notes, foods: [])
                        context.insert(nutritionEntry)
                        for foodData in foodDataArray {
                            if let id = foodData["id"] as? String, let name = foodData["name"] as? String, let brand = foodData["brand"] as? String, let barcode = foodData["barcode"] as? String, let servingSizeDigit = foodData["servingSizeDigit"] as? Double, let servingSizeUnit = foodData["servingSizeUnit"] as? String, let servingsCount = foodData["servingsCount"] as? Double, let date = (foodData["date"] as? Timestamp)?.dateValue(), let mealCategory = foodData["mealCategory"] as? String, let protein = foodData["protein"] as? Double, let carbs = foodData["carbs"] as? Double, let fat = foodData["fat"] as? Double, let calories = foodData["calories"] as? Double {
                                let newFood = NutritionFood(id: id, name: name, brand: brand, barcode: barcode, servingSizeDigit: servingSizeDigit, servingSizeUnit: servingSizeUnit, servingsCount: servingsCount, date: date, mealCategory: mealCategory, protein: protein, carbs: carbs, fat: fat, calories: calories, entry: nutritionEntry)
                                context.insert(newFood)
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
    func fetchNutritionFood(barcode: String, completion: @escaping (NutritionFood?) -> Void) {
        db.collection("NutritionFoods").whereField("barcode", isEqualTo: barcode).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching NutritionFood: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let documents = snapshot?.documents, let document = documents.first else {
                print("No NutritionFood found with the given barcode.")
                completion(nil)
                return
            }
            let data = document.data()
            guard let id = data["id"] as? String,
                  let name = data["name"] as? String,
                  let brand = data["brand"] as? String,
                  let barcode = data["barcode"] as? String,
                  let servingSizeDigit = data["servingSizeDigit"] as? Double,
                  let servingSizeUnit = data["servingSizeUnit"] as? String,
                  let protein = data["protein"] as? Double,
                  let carbs = data["carbs"] as? Double,
                  let fat = data["fat"] as? Double,
                  let calories = data["calories"] as? Double else {
                print("Error parsing NutritionFood data.")
                completion(nil)
                return
            }
            let nutritionFood = NutritionFood(id: id, name: name, brand: brand, barcode: barcode, servingSizeDigit: servingSizeDigit, servingSizeUnit: servingSizeUnit, servingsCount: 0, date: Date(), mealCategory: "", protein: protein, carbs: carbs, fat: fat, calories: calories, entry: nil)
            completion(nutritionFood)
        }
    }
    func createNutritionFood(food: NutritionFood, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        context.insert(food)
        print("Nutrition Food saved to SwiftData")
        var foodData: [String: Any] = [
            "id": food.id,
            "name": food.name,
            "brand": food.brand,
            "barcode": food.barcode,
            "servingSizeDigit": food.servingSizeDigit,
            "servingSizeUnit": food.servingSizeUnit,
            "protein": food.protein,
            "carbs": food.carbs,
            "fat": food.fat,
            "calories": food.calories
        ]
        db.collection("NutritionFoods").document(food.id).setData(foodData)
        print("Nutrition Food saved to Public Firebase")
        foodData["servingsCount"] = food.servingsCount
        foodData["date"] = food.date
        foodData["mealCategory"] = food.mealCategory
        db.collection("users").document(userID).collection("Nutrition").document("NutritionHub").collection("NutritionFoods").document(food.id).setData(foodData)
        print("Nutrition Food saved to Personal Firebase")
    }
    func downloadNutritionFoods(userID: String, context: ModelContext, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userID).collection("Nutrition").document("NutritionHub").collection("NutritionFoods").getDocuments { snapshot, error in
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    if let id = document.data()["id"] as? String,
                       let name = document.data()["name"] as? String,
                       let brand = document.data()["brand"] as? String,
                       let barcode = document.data()["barcode"] as? String,
                       let servingSizeDigit = document.data()["servingSizeDigit"] as? Double,
                       let servingSizeUnit = document.data()["servingSizeUnit"] as? String,
                       let servingsCount = document.data()["servingsCount"] as? Double,
                       let date = (document.data()["date"] as? Timestamp)?.dateValue(),
                       let mealCategory = document.data()["mealCategory"] as? String,
                       let protein = document.data()["protein"] as? Double,
                       let carbs = document.data()["carbs"] as? Double,
                       let fat = document.data()["fat"] as? Double,
                       let calories = document.data()["calories"] as? Double {
                        let newFood = NutritionFood(id: id, name: name, brand: brand, barcode: barcode, servingSizeDigit: servingSizeDigit, servingSizeUnit: servingSizeUnit, servingsCount: servingsCount, date: date, mealCategory: mealCategory, protein: protein, carbs: carbs, fat: fat, calories: calories, entry: nil)
                        context.insert(newFood)
                    }
                }
                completion(true)
            } else {
                print("Error downloading Nutrition Foods: \(String(describing: error))")
                completion(false)
            }
        }
    }
    func addFoodToEntry(food: NutritionFood, entry: NutritionEntry, servingsCount: Double, category: String, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        entry.caloriesConsumed += servingsCount * food.calories
        entry.proteinConsumed += servingsCount * food.protein
        entry.carbsConsumed += servingsCount * food.carbs
        entry.fatConsumed += servingsCount * food.fat
        food.servingsCount = servingsCount
        food.date = Date()
        food.mealCategory = category
        let newFood = NutritionFood(id: UUID().uuidString, name: food.name, brand: food.brand, barcode: food.barcode, servingSizeDigit: food.servingSizeDigit, servingSizeUnit: food.servingSizeUnit, servingsCount: food.servingsCount, date: food.date, mealCategory: food.mealCategory, protein: food.protein, carbs: food.carbs, fat: food.fat, calories: food.calories, entry: entry)
        context.insert(newFood)
        entry.foods!.append(newFood)
        do {
            try context.save()
            print("Nutrtion Entry updated in SwiftData")
        } catch {
            print("Error updating Nutrition Entry and/or Food in SwiftData")
        }
        let foodData: [String: Any] = [
            "id": food.id,
            "name": food.name,
            "brand": food.brand,
            "barcode": food.barcode,
            "servingSizeDigit": food.servingSizeDigit,
            "servingSizeUnit": food.servingSizeUnit,
            "servingsCount": food.servingsCount,
            "date": food.date,
            "mealCategory": food.mealCategory,
            "protein": food.protein,
            "carbs": food.carbs,
            "fat": food.fat,
            "calories": food.calories
        ]
        db.collection("users").document(userID).collection("Nutrition").document("NutritionHub").collection("NutritionFoods").document(food.id).setData(foodData)
        print("Nutrition Food updated in Personal Firebase")
        let entryData: [String: Any] = [
            "id": entry.id,
            "date": entry.date,
            "proteinGoal": entry.proteinGoal,
            "carbsGoal": entry.carbsGoal,
            "fatGoal": entry.fatGoal,
            "caloriesGoal": entry.caloriesGoal,
            "proteinConsumed": entry.proteinConsumed,
            "carbsConsumed": entry.carbsConsumed,
            "fatConsumed": entry.fatConsumed,
            "caloriesConsumed": entry.caloriesConsumed,
            "mealCategories": entry.mealCategories,
            "notes": entry.notes,
            "foods": entry.foods?.map { food in
                return [
                    "id": food.id,
                    "name": food.name,
                    "brand": food.brand,
                    "barcode": food.barcode,
                    "servingSizeDigit": food.servingSizeDigit,
                    "servingSizeUnit": food.servingSizeUnit,
                    "servingsCount": food.servingsCount,
                    "date": food.date,
                    "mealCategory": food.mealCategory,
                    "protein": food.protein,
                    "carbs": food.carbs,
                    "fat": food.fat,
                    "calories": food.calories
                ]
            } ?? []
        ]
        db.collection("users").document(userID).collection("Nutrition").document("NutritionHub").collection("NutritionEntries").document(entry.id).setData(entryData)
        print("Nutrition Entry updated in Firebase")
    }
    func addFirebaseFoodToEntry(food: NutritionFood, entry: NutritionEntry, servingsCount: Double, category: String, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        entry.caloriesConsumed += servingsCount * food.calories
        entry.proteinConsumed += servingsCount * food.protein
        entry.carbsConsumed += servingsCount * food.carbs
        entry.fatConsumed += servingsCount * food.fat
        food.servingsCount = servingsCount
        food.date = Date()
        food.mealCategory = category
        let newFood = NutritionFood(id: UUID().uuidString, name: food.name, brand: food.brand, barcode: food.barcode, servingSizeDigit: food.servingSizeDigit, servingSizeUnit: food.servingSizeUnit, servingsCount: food.servingsCount, date: food.date, mealCategory: food.mealCategory, protein: food.protein, carbs: food.carbs, fat: food.fat, calories: food.calories, entry: entry)
        context.insert(newFood)
        entry.foods!.append(newFood)
        do {
            try context.save()
            print("Nutrtion Entry updated in SwiftData")
        } catch {
            print("Error updating Nutrition Entry and/or Food in SwiftData")
        }
        let entryData: [String: Any] = [
            "id": entry.id,
            "date": entry.date,
            "proteinGoal": entry.proteinGoal,
            "carbsGoal": entry.carbsGoal,
            "fatGoal": entry.fatGoal,
            "caloriesGoal": entry.caloriesGoal,
            "proteinConsumed": entry.proteinConsumed,
            "carbsConsumed": entry.carbsConsumed,
            "fatConsumed": entry.fatConsumed,
            "caloriesConsumed": entry.caloriesConsumed,
            "mealCategories": entry.mealCategories,
            "notes": entry.notes,
            "foods": entry.foods?.map { food in
                return [
                    "id": food.id,
                    "name": food.name,
                    "brand": food.brand,
                    "barcode": food.barcode,
                    "servingSizeDigit": food.servingSizeDigit,
                    "servingSizeUnit": food.servingSizeUnit,
                    "servingsCount": food.servingsCount,
                    "date": food.date,
                    "mealCategory": food.mealCategory,
                    "protein": food.protein,
                    "carbs": food.carbs,
                    "fat": food.fat,
                    "calories": food.calories
                ]
            } ?? []
        ]
        db.collection("users").document(userID).collection("Nutrition").document("NutritionHub").collection("NutritionEntries").document(entry.id).setData(entryData)
        print("Nutrition Entry updated in Firebase")
        let id = food.id
        let fetchDescriptor = FetchDescriptor<NutritionFood>(predicate: #Predicate {
            $0.id == id
        })
        do {
            let existingFoods = try context.fetch(fetchDescriptor)
            if let existingFood = existingFoods.first {
                existingFood.servingsCount = servingsCount
                existingFood.date = food.date
                existingFood.mealCategory = category
            } else {
                let newFood = NutritionFood(
                    id: UUID().uuidString,
                    name: food.name,
                    brand: food.brand,
                    barcode: food.barcode,
                    servingSizeDigit: food.servingSizeDigit,
                    servingSizeUnit: food.servingSizeUnit,
                    servingsCount: food.servingsCount,
                    date: food.date,
                    mealCategory: food.mealCategory,
                    protein: food.protein,
                    carbs: food.carbs,
                    fat: food.fat,
                    calories: food.calories,
                    entry: entry
                )
                context.insert(newFood)
                if entry.foods == nil {
                    entry.foods = []
                }
                entry.foods!.append(newFood)
            }
            try context.save()
            print("Nutrition Entry updated in SwiftData")
        } catch {
            print("Error updating or inserting Nutrition Food in SwiftData: \(error.localizedDescription)")
        }
        let foodData: [String: Any] = [
            "id": food.id,
            "name": food.name,
            "brand": food.brand,
            "barcode": food.barcode,
            "servingSizeDigit": food.servingSizeDigit,
            "servingSizeUnit": food.servingSizeUnit,
            "servingsCount": food.servingsCount,
            "date": food.date,
            "mealCategory": food.mealCategory,
            "protein": food.protein,
            "carbs": food.carbs,
            "fat": food.fat,
            "calories": food.calories
        ]
        db.collection("users").document(userID).collection("Nutrition").document("NutritionHub").collection("NutritionFoods").document(food.id).setData(foodData)
        print("Nutrition Food updated in Personal Firebase")
    }
    func editEntryFood(entry: NutritionEntry, food: NutritionFood, servingsCount: Double, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        entry.caloriesConsumed -= food.servingsCount * food.calories
        entry.proteinConsumed -= food.servingsCount * food.protein
        entry.carbsConsumed -= food.servingsCount * food.carbs
        entry.fatConsumed -= food.servingsCount * food.fat
        entry.caloriesConsumed += servingsCount * food.calories
        entry.proteinConsumed += servingsCount * food.protein
        entry.carbsConsumed += servingsCount * food.carbs
        entry.fatConsumed += servingsCount * food.fat
        food.servingsCount = servingsCount
        do {
            try context.save()
            print("Updated food for entry in SwiftData")
        } catch {
            print("Failed to update food for entry in SwiftData")
        }
        let entryData: [String: Any] = [
            "id": entry.id,
            "date": entry.date,
            "proteinGoal": entry.proteinGoal,
            "carbsGoal": entry.carbsGoal,
            "fatGoal": entry.fatGoal,
            "caloriesGoal": entry.caloriesGoal,
            "proteinConsumed": entry.proteinConsumed,
            "carbsConsumed": entry.carbsConsumed,
            "fatConsumed": entry.fatConsumed,
            "caloriesConsumed": entry.caloriesConsumed,
            "mealCategories": entry.mealCategories,
            "notes": entry.notes,
            "foods": entry.foods?.map { food in
                return [
                    "id": food.id,
                    "name": food.name,
                    "brand": food.brand,
                    "barcode": food.barcode,
                    "servingSizeDigit": food.servingSizeDigit,
                    "servingSizeUnit": food.servingSizeUnit,
                    "servingsCount": food.servingsCount,
                    "date": food.date,
                    "mealCategory": food.mealCategory,
                    "protein": food.protein,
                    "carbs": food.carbs,
                    "fat": food.fat,
                    "calories": food.calories
                ]
            } ?? []
        ]
        db.collection("users").document(userID).collection("Nutrition").document("NutritionHub").collection("NutritionEntries").document(entry.id).setData(entryData)
        print("Nutrition Entry updated in Firebase")
    }
    func deleteFood(food: NutritionFood, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        context.delete(food)
        print("Nutrition Food deleted from SwiftData")
        db.collection("users").document(userID).collection("Nutrition").document("NutritionHub").collection("NutritionFoods").document(food.id).delete()
        print("Nutrition Food deleted from Firebase")
    }
    func deleteEntryFood(entry: NutritionEntry, food: NutritionFood, context: ModelContext) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in.")
            return
        }
        entry.caloriesConsumed -= food.servingsCount * food.calories
        entry.proteinConsumed -= food.servingsCount * food.protein
        entry.carbsConsumed -= food.servingsCount * food.carbs
        entry.fatConsumed -= food.servingsCount * food.fat
        
        if let index = entry.foods!.firstIndex(of: food) {
            entry.foods!.remove(at: index)
        }
        context.delete(food)
        print("Food removed from Nutrition Entry in SwiftData")
        do {
            try context.save()
            print("Nutrition Entry updated in SwiftData")
        } catch {
            print("Error updating Nutrition Entry in SwiftData: \(error.localizedDescription)")
        }
        let entryData: [String: Any] = [
            "id": entry.id,
            "date": entry.date,
            "proteinGoal": entry.proteinGoal,
            "carbsGoal": entry.carbsGoal,
            "fatGoal": entry.fatGoal,
            "caloriesGoal": entry.caloriesGoal,
            "proteinConsumed": entry.proteinConsumed,
            "carbsConsumed": entry.carbsConsumed,
            "fatConsumed": entry.fatConsumed,
            "caloriesConsumed": entry.caloriesConsumed,
            "mealCategories": entry.mealCategories,
            "notes": entry.notes,
            "foods": entry.foods?.map { food in
                return [
                    "id": food.id,
                    "name": food.name,
                    "brand": food.brand,
                    "barcode": food.barcode,
                    "servingSizeDigit": food.servingSizeDigit,
                    "servingSizeUnit": food.servingSizeUnit,
                    "servingsCount": food.servingsCount,
                    "date": food.date,
                    "mealCategory": food.mealCategory,
                    "protein": food.protein,
                    "carbs": food.carbs,
                    "fat": food.fat,
                    "calories": food.calories
                ]
            } ?? []
        ]
        db.collection("users").document(userID).collection("Nutrition").document("NutritionHub").collection("NutritionEntries").document(entry.id).setData(entryData)
        print("Nutrition Entry updated in Firebase")
    }
}
