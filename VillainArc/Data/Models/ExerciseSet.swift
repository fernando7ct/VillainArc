import Foundation
import SwiftData

@Model
class ExerciseSet {
    var id: UUID
    var type: ExerciseSetType
    var weight: Double
    var reps: Int
    var complete: Bool
    var exercise: WorkoutExercise
    
    init(id: UUID = UUID(), type: ExerciseSetType = .regular, weight: Double = 0.0, reps: Int = 0, complete: Bool = false, exercise: WorkoutExercise) {
        self.id = id
        self.type = type
        self.weight = weight
        self.reps = reps
        self.complete = complete
        self.exercise = exercise
    }
}

extension ExerciseSet {
    static func sampleSet1(for exercise: WorkoutExercise) -> [ExerciseSet] {
        [
            ExerciseSet(type: .regular, weight: 135, reps: 10, exercise: exercise),
            ExerciseSet(type: .regular, weight: 185, reps: 8, exercise: exercise),
            ExerciseSet(type: .regular, weight: 205, reps: 6, exercise: exercise)
        ]
    }

    static func sampleSet2(for exercise: WorkoutExercise) -> [ExerciseSet] {
        [
            ExerciseSet(type: .warmup, weight: 45, reps: 12, exercise: exercise),
            ExerciseSet(type: .regular, weight: 95, reps: 10, exercise: exercise),
            ExerciseSet(type: .regular, weight: 115, reps: 8, exercise: exercise)
        ]
    }

    static func sampleSet3(for exercise: WorkoutExercise) -> [ExerciseSet] {
        [
            ExerciseSet(type: .regular, weight: 50, reps: 15, exercise: exercise),
            ExerciseSet(type: .regular, weight: 60, reps: 12, exercise: exercise),
            ExerciseSet(type: .failure, weight: 60, reps: 10, exercise: exercise)
        ]
    }

    static func sampleSet4(for exercise: WorkoutExercise) -> [ExerciseSet] {
        [
            ExerciseSet(type: .regular, weight: 25, reps: 12, exercise: exercise),
            ExerciseSet(type: .regular, weight: 30, reps: 10, exercise: exercise),
            ExerciseSet(type: .dropSet, weight: 20, reps: 12, exercise: exercise)
        ]
    }

    static func sampleSet5(for exercise: WorkoutExercise) -> [ExerciseSet] {
        [
            ExerciseSet(type: .regular, weight: 100, reps: 5, exercise: exercise),
            ExerciseSet(type: .regular, weight: 120, reps: 5, exercise: exercise),
            ExerciseSet(type: .regular, weight: 135, reps: 5, exercise: exercise)
        ]
    }
}
