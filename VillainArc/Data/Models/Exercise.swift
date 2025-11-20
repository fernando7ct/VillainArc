import Foundation
import SwiftData

@Model
class Exercise {
    var id: UUID = UUID()
    var name: String = ""
    var musclesTargeted: [Muscle] = []
    var isCustom: Bool = false
    var lastUsed: Date? = nil

    init(from exerciseDetails: ExerciseDetails) {
        self.name = exerciseDetails.rawValue
        self.musclesTargeted = exerciseDetails.musclesTargeted
    }

    init(name: String, musclesTargeted: [Muscle]) {
        self.name = name
        self.musclesTargeted = musclesTargeted
        self.isCustom = true
    }
}
