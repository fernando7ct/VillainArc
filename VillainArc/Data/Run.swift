import SwiftData
import SwiftUI
import CoreLocation

@Model
class Run {
    var id: String = UUID().uuidString
    var startTime: Date = Date()
    var endTime: Date = Date()
    var distance: Double = 0
    var locations: [[Double]] = []
    
    init(id: String, startTime: Date, endTime: Date, distance: Double, locations: [[Double]]) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.distance = distance
        self.locations = locations
    }
}
extension Run {
    func toDictionary() -> [String: Any] {
        return [
            "id": self.id,
            "startTime": self.startTime,
            "endTime": self.endTime,
            "distance": self.distance,
            "locations": self.locations
        ]
    }
}
