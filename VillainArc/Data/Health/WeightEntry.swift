import Foundation
import SwiftData

@Model
class WeightEntry: Identifiable {
    var id: String = UUID().uuidString
    var weight: Double = 0
    var notes: String = ""
    var date: Date = Date()
    @Attribute(.externalStorage)
    var photoData: Data?
    
    init(id: String, weight: Double, notes: String, date: Date, photoData: Data?) {
        self.id = id
        self.weight = weight
        self.notes = notes
        self.date = date
        self.photoData = photoData
    }
}

extension WeightEntry {
    static func -(lhs: WeightEntry, rhs: WeightEntry) -> Double {
        return lhs.weight - rhs.weight
    }
}
