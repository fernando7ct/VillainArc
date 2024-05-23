import Foundation
import SwiftData

@Model
class WeightEntry {
    var id: String
    var weight: Double
    var notes: String
    var date: Date
    
    init(id: String, weight: Double, notes: String, date: Date) {
        self.id = id
        self.weight = weight
        self.notes = notes
        self.date = date
    }
}
