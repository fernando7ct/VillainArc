import Foundation
import SwiftData

@Model
class Nutrition {
    var id: String = UUID().uuidString
    var proteinGoal: Double = 0
    var carbsGoal: Double = 0
    var fatGoal: Double = 0
    var caloriesGoal: Double = 0
    var mealCategories: [String] = []
    @Relationship(deleteRule: .cascade)
    var entries: [NutritionEntry]?
    
    init(id: String, proteinGoal: Double, carbsGoal: Double, fatGoal: Double, caloriesGoal: Double, mealCategories: [String], entries: [NutritionEntry]) {
        self.id = id
        self.proteinGoal = proteinGoal
        self.carbsGoal = carbsGoal
        self.fatGoal = fatGoal
        self.caloriesGoal = caloriesGoal
        self.mealCategories = mealCategories
        self.entries = entries
    }
}
