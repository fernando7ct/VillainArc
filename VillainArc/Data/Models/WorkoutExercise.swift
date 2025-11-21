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
    
    init(from exercise: WorkoutExercise, workout: Workout?) {
        name = exercise.name
        notes = exercise.notes
        repRange = exercise.repRange
        musclesTargeted = exercise.musclesTargeted
        self.workout = workout
        for exerciseSet in exercise.sets {
            sets.append(ExerciseSet(from: exerciseSet))
        }
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
