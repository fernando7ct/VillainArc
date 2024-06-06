import Foundation
import SwiftData

@Model
class WeightEntry {
    var id: String = UUID().uuidString
    var weight: Double = 0
    var notes: String = ""
    var date: Date = Date()
    
    init(id: String, weight: Double, notes: String, date: Date) {
        self.id = id
        self.weight = weight
        self.notes = notes
        self.date = date
    }
}
