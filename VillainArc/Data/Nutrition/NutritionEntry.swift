import Foundation
import SwiftData

@Model
class NutritionEntry {
    var id: String = UUID().uuidString
    var date: Date = Date()
    var proteinGoal: Double = 0
    var carbsGoal: Double = 0
    var fatGoal: Double = 0
    var caloriesGoal: Double = 0
    var proteinConsumed: Double = 0
    var carbsConsumed: Double = 0
    var fatConsumed: Double = 0
    var caloriesConsumed: Double = 0
    var mealCategories: [String] = []
    var notes: String = ""
    @Relationship(deleteRule: .cascade)
    var foods: [NutritionFood]?
    
    init(id: String, date: Date, proteinGoal: Double, carbsGoal: Double, fatGoal: Double, caloriesGoal: Double, proteinConsumed: Double, carbsConsumed: Double, fatConsumed: Double, caloriesConsumed: Double, mealCategories: [String], notes: String, foods: [NutritionFood]) {
        self.id = id
        self.date = date
        self.proteinGoal = proteinGoal
        self.carbsGoal = carbsGoal
        self.fatGoal = fatGoal
        self.caloriesGoal = caloriesGoal
        self.proteinConsumed = proteinConsumed
        self.carbsConsumed = carbsConsumed
        self.fatConsumed = fatConsumed
        self.caloriesConsumed = caloriesConsumed
        self.mealCategories = mealCategories
        self.notes = notes
        self.foods = foods
    }
}
extension NutritionEntry {
    func toDictionary() -> [String: Any] {
        return [
            "id": self.id,
            "date": self.date,
            "proteinGoal": self.proteinGoal,
            "carbsGoal": self.carbsGoal,
            "fatGoal": self.fatGoal,
            "caloriesGoal": self.caloriesGoal,
            "proteinConsumed": self.proteinConsumed,
            "carbsConsumed": self.carbsConsumed,
            "fatConsumed": self.fatConsumed,
            "caloriesConsumed": self.caloriesConsumed,
            "mealCategories": self.mealCategories,
            "notes": self.notes,
            "foods": self.foods?.map { food in
                return [
                    "id": food.id,
                    "name": food.name,
                    "brand": food.brand,
                    "barcode": food.barcode,
                    "servingSizeDigit": food.servingSizeDigit,
                    "servingSizeUnit": food.servingSizeUnit,
                    "servingSizeDigit2": food.servingSizeDigit2,
                    "servingSizeUnit2": food.servingSizeUnit2,
                    "servingsCount": food.servingsCount,
                    "servingsPerContainer": food.servingsPerContainer,
                    "date": food.date,
                    "mealCategory": food.mealCategory,
                    "protein": food.protein,
                    "carbs": food.carbs,
                    "fat": food.fat,
                    "calories": food.calories
                ]
            } ?? []
        ]
    }
}
