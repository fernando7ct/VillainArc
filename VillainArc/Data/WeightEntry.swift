import Foundation
import SwiftData

@Model
class WeightEntry {
    var id: String
    var weight: Double
    var date: Date
    
    init(id: String, weight: Double, date: Date) {
        self.id = id
        self.weight = weight
        self.date = date
    }
}
