import Foundation
import SwiftData

@Model
class HealthSteps: Identifiable {
    var id: String = UUID().uuidString
    var date: Date = Date()
    var steps: Double = 0
    var goal: Double = 0
    var goalMet: Bool = false
    
    init(id: String, date: Date, steps: Double, goal: Double = 0, goalMet: Bool = false) {
        self.id = id
        self.date = date
        self.steps = steps
        self.goal = goal
        self.goalMet = goalMet
    }
}
extension HealthSteps {
    func toDictionary() -> [String : Any] {
        return [
            "id": self.id,
            "date": self.date,
            "steps": self.steps,
            "goal": self.goal,
            "goalMet": self.goalMet
        ]
    }
}
