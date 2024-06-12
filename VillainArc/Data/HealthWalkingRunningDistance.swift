import Foundation
import SwiftData

@Model
class HealthWalkingRunningDistance: Identifiable {
    var id: String = UUID().uuidString
    var date: Date = Date()
    var distance: Double = 0
    
    init(id: String, date: Date, distance: Double) {
        self.id = id
        self.date = date
        self.distance = distance
    }
}
