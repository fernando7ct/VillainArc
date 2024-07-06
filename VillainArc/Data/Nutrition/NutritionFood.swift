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
    var servingSizeDigit2: Double = 0
    var servingSizeUnit2: String = ""
    var servingsCount: Double = 0
    var servingsPerContainer: Double = 0
    var date: Date = Date()
    var mealCategory: String = ""
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var calories: Double = 0
    var entry: NutritionEntry?
    
    init(id: String, name: String, brand: String, barcode: String, servingSizeDigit: Double, servingSizeUnit: String, servingSizeDigit2: Double, servingSizeUnit2: String, servingsCount: Double, servingsPerContainer: Double, date: Date, mealCategory: String, protein: Double, carbs: Double, fat: Double, calories: Double, entry: NutritionEntry?) {
        self.id = id
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.servingSizeDigit = servingSizeDigit
        self.servingSizeUnit = servingSizeUnit
        self.servingSizeDigit2 = servingSizeDigit2
        self.servingSizeUnit2 = servingSizeUnit2
        self.servingsCount = servingsCount
        self.servingsPerContainer = servingsPerContainer
        self.date = date
        self.mealCategory = mealCategory
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.calories = calories
        self.entry = entry
    }
}
extension NutritionFood {
    func toDictionary(includePersonalData: Bool = false) -> [String: Any] {
        var foodData: [String: Any] = [
            "id": self.id,
            "name": self.name,
            "brand": self.brand,
            "barcode": self.barcode,
            "servingSizeDigit": self.servingSizeDigit,
            "servingSizeUnit": self.servingSizeUnit,
            "servingSizeDigit2": self.servingSizeDigit2,
            "servingSizeUnit2": self.servingSizeUnit2,
            "servingsPerContainer": self.servingsPerContainer,
            "protein": self.protein,
            "carbs": self.carbs,
            "fat": self.fat,
            "calories": self.calories
        ]
        
        if includePersonalData {
            foodData["servingsCount"] = self.servingsCount
            foodData["date"] = self.date
            foodData["mealCategory"] = self.mealCategory
        }
        
        return foodData
    }
}
