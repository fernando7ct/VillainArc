import Foundation
import SwiftData

@Model
class HealthActiveEnergy: Identifiable {
    var id: String = UUID().uuidString
    var date: Date = Date()
    var activeEnergy: Double = 0
    
    init(id: String, date: Date, activeEnergy: Double) {
        self.id = id
        self.date = date
        self.activeEnergy = activeEnergy
    }
}
extension HealthActiveEnergy {
    func toDictionary() -> [String: Any] {
        return [
            "id": self.id,
            "date": self.date,
            "activeEnergy": self.activeEnergy
        ]
    }
}
