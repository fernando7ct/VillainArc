import Foundation
import SwiftData

@Model
class WorkoutExercise {
    var id: String
    var name: String
    var category: String
    var notes: String
    var date: Date
    var order: Int
    var workout: Workout
    var sets: [ExerciseSet]
    
    init(id: String, name: String, category: String, notes: String, date: Date, order: Int, workout: Workout, sets: [ExerciseSet]) {
        self.id = id
        self.name = name
        self.category = category
        self.notes = notes
        self.date = date
        self.order = order
        self.workout = workout
        self.sets = sets
    }
}

struct TempExercise: Identifiable {
    var id = UUID()
    var name: String
    var category: String
    var notes: String
    var sets: [TempSet]
    
    init(name: String, category: String, notes: String, sets: [TempSet]) {
        self.name = name
        self.category = category
        self.notes = notes
        self.sets = sets
    }
    
    init(from exercise: WorkoutExercise) {
        self.name = exercise.name
        self.category = exercise.category
        self.notes = exercise.notes
        self.sets = exercise.sets.sorted(by: { $0.order < $1.order }).map { TempSet(from: $0) }
    }
}
