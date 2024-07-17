import Foundation
import SwiftData

@Model
class WorkoutExercise: Identifiable {
    var id: String = UUID().uuidString
    var name: String = ""
    var category: String = ""
    var repRange: String = ""
    var notes: String = ""
    var date: Date = Date()
    var order: Int = 0
    var sameRestTimes: Bool = false
    var workout: Workout?
    @Relationship(deleteRule: .cascade) var sets: [ExerciseSet] = []
    
    init(id: String, name: String, category: String, repRange: String, notes: String, date: Date, order: Int, sameRestTimes: Bool, workout: Workout, sets: [ExerciseSet]) {
        self.id = id
        self.name = name
        self.category = category
        self.repRange = repRange
        self.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        self.date = date
        self.order = order
        self.sameRestTimes = sameRestTimes
        self.workout = workout
        self.sets = sets
    }
    init(id: String, tempExercise: TempExercise, date: Date, order: Int, workout: Workout, sets: [ExerciseSet]) {
        self.id = id
        self.name = tempExercise.name
        self.category = tempExercise.category
        self.repRange = tempExercise.repRange
        self.notes = tempExercise.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        self.date = date
        self.order = order
        self.sameRestTimes = tempExercise.sameRestTimes
        self.workout = workout
        self.sets = sets
    }
    init(id: String, exercise: WorkoutExercise, date: Date, workout: Workout, sets: [ExerciseSet]) {
        self.id = id
        self.name = exercise.name
        self.category = exercise.category
        self.repRange = exercise.repRange
        self.notes = exercise.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        self.date = date
        self.order = exercise.order
        self.sameRestTimes = exercise.sameRestTimes
        self.workout = workout
        self.sets = sets
    }
}

struct TempExercise: Identifiable {
    var id = UUID()
    var name: String
    var category: String
    var repRange: String
    var notes: String
    var sameRestTimes: Bool
    var sets: [TempSet]
    
    init(name: String, category: String, repRange: String, notes: String, sameRestTimes: Bool, sets: [TempSet]) {
        self.name = name
        self.category = category
        self.repRange = repRange
        self.notes = notes
        self.sameRestTimes = sameRestTimes
        self.sets = sets
    }
    
    init(from exercise: WorkoutExercise) {
        self.name = exercise.name
        self.category = exercise.category
        self.repRange = exercise.repRange
        self.notes = exercise.notes
        self.sameRestTimes = exercise.sameRestTimes
        self.sets = exercise.sets.sorted(by: { $0.order < $1.order }).map { TempSet(from: $0) }
    }
}
struct ExerciseInfo {
    var name: String
    var category: String
    var count: Int
    var sets: [ExerciseSet]
}
extension WorkoutExercise {
    func toDictionary() -> [String: Any] {
        return [
            "id": self.id,
            "name": self.name,
            "category": self.category,
            "repRange": self.repRange,
            "notes": self.notes,
            "date": self.date,
            "order": self.order,
            "sameRestTimes": self.sameRestTimes,
            "sets": self.sets.map { $0.toDictionary() }
        ]
    }
}
