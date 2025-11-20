import Foundation
import SwiftData

@Model
class ExerciseSet {
    var id: UUID = UUID()
    var type: ExerciseSetType = ExerciseSetType.regular
    var weight: Double = 0
    var reps: Int = 0
    var complete: Bool = false
    
    init(from set: ExerciseSet) {
        type = set.type
        weight = set.weight
        reps = set.reps
    }
    
    // Testing
    init(type: ExerciseSetType = .regular, weight: Double = 0.0, reps: Int = 0) {
        self.type = type
        self.weight = weight
        self.reps = reps
    }
}
