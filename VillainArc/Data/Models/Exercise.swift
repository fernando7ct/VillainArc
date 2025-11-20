import Foundation
import SwiftData

@Model
class Exercise {
    var id: UUID
    var name: String
    var musclesTargeted: [Muscle]
    var isCustom: Bool
    var lastUsed: Date?

    init(from exerciseDetails: ExerciseDetails) {
        self.id = UUID()
        self.name = exerciseDetails.rawValue
        self.musclesTargeted = exerciseDetails.musclesTargeted
        self.isCustom = false
        self.lastUsed = nil
    }

    init(name: String, musclesTargeted: [Muscle]) {
        self.id = UUID()
        self.name = name
        self.musclesTargeted = musclesTargeted
        self.isCustom = true
        self.lastUsed = nil
    }
}
