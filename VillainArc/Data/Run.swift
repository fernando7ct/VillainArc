import SwiftUI
import SwiftData

@Model
class Run {
    var id: String = UUID().uuidString
    var startTime: Date = Date()
    var endTime: Date = Date()
    var distance: Double = 0
    var averagePace: Double = 0
    var mileSplits: [[Double]] = []

    init(id: String, startTime: Date, endTime: Date, distance: Double, averagePace: Double, mileSplits: [[Double]]) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.distance = distance
        self.averagePace = averagePace
        self.mileSplits = mileSplits
    }
}
extension Run {
    func toDictionary() -> [String: Any] {
        return [
            "id": self.id,
            "startTime": self.startTime,
            "endTime": self.endTime,
            "distance": self.distance,
            "averagePace": self.averagePace,
            "mileSplits": self.mileSplits.map { ["mile": $0[0], "pace": $0[1]] }
        ]
    }
}
