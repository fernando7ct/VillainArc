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
