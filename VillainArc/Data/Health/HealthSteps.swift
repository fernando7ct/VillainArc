import Foundation
import SwiftData

@Model
class HealthSteps: Identifiable {
    var id: String = UUID().uuidString
    var date: Date = Date()
    var steps: Double = 0
    
    init(id: String, date: Date, steps: Double) {
        self.id = id
        self.date = date
        self.steps = steps
    }
}
