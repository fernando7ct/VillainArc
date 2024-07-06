import Foundation
import SwiftData

@Model
class HealthRestingEnergy: Identifiable {
    var id: String = UUID().uuidString
    var date: Date = Date()
    var restingEnergy: Double = 0
    
    init(id: String, date: Date, restingEnergy: Double) {
        self.id = id
        self.date = date
        self.restingEnergy = restingEnergy
    }
}
extension HealthRestingEnergy {
    func toDictionary() -> [String: Any] {
        return [
            "id": self.id,
            "date": self.date,
            "activeEnergy": self.restingEnergy
        ]
    }
}
