import Foundation
import SwiftData

@Model
class NutritionFood: Identifiable {
    var id: String = UUID().uuidString
    var name: String = ""
    var brand: String = ""
    var barcode: String = ""
    var servingSizeDigit: Double = 0
    var servingSizeUnit: String = ""
    var servingsCount: Double = 0
    var date: Date = Date()
    var mealCategory: String = ""
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var calories: Double = 0
    var entry: NutritionEntry?
    
    init(id: String, name: String, brand: String, barcode: String, servingSizeDigit: Double, servingSizeUnit: String, servingsCount: Double, date: Date, mealCategory: String, protein: Double, carbs: Double, fat: Double, calories: Double, entry: NutritionEntry?) {
        self.id = id
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.servingSizeDigit = servingSizeDigit
        self.servingSizeUnit = servingSizeUnit
        self.servingsCount = servingsCount
        self.date = date
        self.mealCategory = mealCategory
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.calories = calories
        self.entry = entry
    }
}
