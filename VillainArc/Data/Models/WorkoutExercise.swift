import Foundation
import SwiftData

@Model
class WorkoutExercise {
    var id: UUID = UUID()
    var name: String = ""
    var notes: String = ""
    var repRange: RepRange = RepRange.notSet
    var date: Date = Date.now
    var musclesTargeted: [Muscle] = []
    var workout: Workout?
    @Relationship(deleteRule: .cascade)
    var sets: [ExerciseSet] = []
    
    var displayMuscle: String {
        musclesTargeted.filter(\.isMajor).first?.rawValue ?? ""
    }
    
    init(from exercise: Exercise, workout: Workout?) {
        name = exercise.name
        musclesTargeted = exercise.musclesTargeted
        self.workout = workout
    }
    
    func addSet() {
        if let previous = sets.last {
            sets.append(ExerciseSet(weight: previous.weight, reps: previous.reps))
        } else {
            sets.append(ExerciseSet())
        }
    }
    
    func removeSet(_ set: ExerciseSet) {
        sets.removeAll { $0 == set }
    }
    
    // Testing
    init(name: String, notes: String = "", repRange: RepRange = .notSet, musclesTargeted: [Muscle], workout: Workout?, sets: [ExerciseSet]) {
        self.name = name
        self.notes = notes
        self.repRange = repRange
        self.musclesTargeted = musclesTargeted
        self.workout = workout
        self.sets = sets
    }
}
