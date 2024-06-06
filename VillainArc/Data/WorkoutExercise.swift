import Foundation
import SwiftData

@Model
class WorkoutExercise: Identifiable {
    var id: String = UUID().uuidString
    var name: String = ""
    var category: String = ""
    var notes: String = ""
    var date: Date = Date()
    var order: Int = 0
    var workout: Workout?
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.exercise)
    var sets: [ExerciseSet]?
    
    init(id: String, name: String, category: String, notes: String, date: Date, order: Int, workout: Workout, sets: [ExerciseSet]) {
        self.id = id
        self.name = name
        self.category = category
        self.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        self.date = date
        self.order = order
        self.workout = workout
        self.sets = sets
    }
    init(id: String, tempExercise: TempExercise, date: Date, order: Int, workout: Workout, sets: [ExerciseSet]) {
        self.id = id
        self.name = tempExercise.name
        self.category = tempExercise.category
        self.notes = tempExercise.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        self.date = date
        self.order = order
        self.workout = workout
        self.sets = sets
    }
    init(id: String, exercise: WorkoutExercise, date: Date, workout: Workout, sets: [ExerciseSet]) {
        self.id = id
        self.name = exercise.name
        self.category = exercise.category
        self.notes = exercise.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        self.date = date
        self.order = exercise.order
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
        self.sets = exercise.sets!.sorted(by: { $0.order < $1.order }).map { TempSet(from: $0) }
    }
}
struct ExerciseInfo {
    var name: String
    var category: String
    var count: Int
    var sets: [ExerciseSet]
}
