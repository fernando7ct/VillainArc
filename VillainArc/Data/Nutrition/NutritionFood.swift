import Foundation
import SwiftData

@Model
class NutritionFood {
    var id: String = UUID().uuidString
    var name: String = ""
    var brand: String = ""
    var servingSize: String = ""
    var numberOfServings: Double = 0
    var time: Date = Date()
    var mealCategory: String = ""
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    
    init(id: String, name: String, brand: String, servingSize: String, numberOfServings: Double, time: Date, mealCategory: String, calories: Double, protein: Double, carbs: Double, fat: Double) {
        self.id = id
        self.name = name
        self.brand = brand
        self.servingSize = servingSize
        self.numberOfServings = numberOfServings
        self.time = time
        self.mealCategory = mealCategory
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}
