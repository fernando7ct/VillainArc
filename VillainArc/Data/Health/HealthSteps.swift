import Foundation
import SwiftData

@Model
class HealthSteps: Identifiable {
    var id: String = UUID().uuidString
    var date: Date = Date()
    var steps: Double = 0
    var goal: Double = 0
    
    init(id: String, date: Date, steps: Double) {
        self.id = id
        self.date = date
        self.steps = steps
    }
}
extension HealthSteps {
    func toDictionary() -> [String : Any] {
        return [
            "id": self.id,
            "date": self.date,
            "steps": self.steps
        ]
    }
}
