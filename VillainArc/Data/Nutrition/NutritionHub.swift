import Foundation
import SwiftData

@Model
class NutritionHub {
    var id: String = UUID().uuidString
    var goal: Double = 0
    var proteinGoal: Double = 0
    var carbsGoal: Double = 0
    var fatGoal: Double = 0
    var caloriesGoal: Double = 0
    var proteinPercentage: Double = 0
    var carbsPercentage: Double = 0
    var fatPercentage: Double = 0
    var activityLevel: Double = 0
    var mealCategories: [String] = []
    
    init(id: String, goal: Double, proteinGoal: Double, carbsGoal: Double, fatGoal: Double, caloriesGoal: Double, proteinPercentage: Double, carbsPercentage: Double, fatPercentage: Double, activityLevel: Double, mealCategories: [String]) {
        self.id = id
        self.goal = goal
        self.proteinGoal = proteinGoal
        self.carbsGoal = carbsGoal
        self.fatGoal = fatGoal
        self.caloriesGoal = caloriesGoal
        self.proteinPercentage = proteinPercentage
        self.carbsPercentage = carbsPercentage
        self.fatPercentage = fatPercentage
        self.activityLevel = activityLevel
        self.mealCategories = mealCategories
    }
}
extension NutritionHub {
    func toDictionary() -> [String: Any] {
        return [
            "id": self.id,
            "goal": self.goal,
            "proteinGoal": self.proteinGoal,
            "carbsGoal": self.carbsGoal,
            "fatGoal": self.fatGoal,
            "caloriesGoal": self.caloriesGoal,
            "proteinPercentage": self.proteinPercentage,
            "carbsPercentage": self.carbsPercentage,
            "fatPercentage": self.fatPercentage,
            "activityLevel": self.activityLevel,
            "mealCategories": self.mealCategories
        ]
    }
}
