import Foundation
import SwiftData

@Model
class HealthEnergy: Identifiable {
    var id: String = UUID().uuidString
    var date: Date = Date()
    var restingEnergy: Double = 0
    var activeEnergy: Double = 0
    
    var total: Double {
        self.restingEnergy + self.activeEnergy
    }
    
    init(id: String, date: Date, restingEnergy: Double, activeEnergy: Double) {
        self.id = id
        self.date = date
        self.restingEnergy = restingEnergy
        self.activeEnergy = activeEnergy
    }
}
extension HealthEnergy {
    func toDictionary() -> [String: Any] {
        return [
            "id": self.id,
            "date": self.date,
            "restingEnergy": self.restingEnergy,
            "activeEnergy": self.activeEnergy
        ]
    }
}
