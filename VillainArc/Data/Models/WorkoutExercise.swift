import Foundation
import SwiftData

@Model
class WorkoutExercise {
    var id: UUID
    var name: String
    var notes: String
    var repRange: RepRange
    var date: Date
    var musclesTargeted: [Muscle]
    var workout: Workout?
    @Relationship(deleteRule: .cascade)
    var sets: [ExerciseSet]
    
    var displayMuscle: String {
        musclesTargeted.filter({ $0.isMajor }).first?.rawValue ?? musclesTargeted.first!.rawValue
    }
    
    init(name: String, notes: String = "", repRange: RepRange = .notSet, musclesTargeted: [Muscle], workout: Workout?) {
        self.id = UUID()
        self.name = name
        self.notes = notes
        self.repRange = repRange
        self.date = .now
        self.musclesTargeted = musclesTargeted
        self.workout = workout
        self.sets = []
    }

    init(from exercise: Exercise, workout: Workout?) {
        self.id = UUID()
        self.name = exercise.name
        self.notes = ""
        self.repRange = .notSet
        self.date = .now
        self.musclesTargeted = exercise.musclesTargeted
        self.workout = workout
        self.sets = []
    }
}


extension WorkoutExercise {
    static func chestDay(for workout: Workout) -> [WorkoutExercise] {
        let e1 = WorkoutExercise(name: "Barbell Bench Press", notes: "Warm-up + 3x5 @ RPE 8", musclesTargeted: [.chest, .midChest, .frontDelt, .triceps], workout: workout)
        e1.sets = ExerciseSet.sampleSet1(for: e1)

        let e2 = WorkoutExercise(name: "Incline Dumbbell Press", notes: "3x8–10", repRange: .range(lower: 8, upper: 10), musclesTargeted: [.upperChest, .chest, .frontDelt, .triceps], workout: workout)
        e2.sets = ExerciseSet.sampleSet2(for: e2)

        let e3 = WorkoutExercise(name: "Cable Chest Fly", notes: "3x12–15, slow eccentric", repRange: .range(lower: 12, upper: 15), musclesTargeted: [.chest, .midChest, .frontDelt], workout: workout)
        e3.sets = ExerciseSet.sampleSet3(for: e3)

        let e4 = WorkoutExercise(name: "Push-ups", notes: "2xAMRAP", repRange: .untilFailure, musclesTargeted: [.chest, .midChest, .frontDelt, .triceps], workout: workout)
        e4.sets = ExerciseSet.sampleSet4(for: e4)

        return [e1, e2, e3, e4]
    }
    
    static func backDay(for workout: Workout) -> [WorkoutExercise] {
        let e1 = WorkoutExercise(name: "Deadlift", notes: "Warm-up + 3x3 @ RPE 8", repRange: .exact(3), musclesTargeted: [.hamstrings, .glutes, .lowerBack, .back], workout: workout)
        e1.sets = ExerciseSet.sampleSet1(for: e1)

        let e2 = WorkoutExercise(name: "Bent-Over Row", notes: "4x8, straps optional", musclesTargeted: [.back, .lats, .rhomboids, .rearDelt], workout: workout)
        e2.sets = ExerciseSet.sampleSet2(for: e2)

        let e3 = WorkoutExercise(name: "Lat Pulldown", notes: "3x10–12", repRange: .range(lower: 10, upper: 12), musclesTargeted: [.lats, .back, .biceps], workout: workout)
        e3.sets = ExerciseSet.sampleSet3(for: e3)

        let e4 = WorkoutExercise(name: "Face Pull", notes: "3x15, focus on scapular movement", repRange: .exact(15), musclesTargeted: [.rearDelt, .rhomboids, .shoulders], workout: workout)
        e4.sets = ExerciseSet.sampleSet4(for: e4)

        return [e1, e2, e3, e4]
    }
    
    static func shoulderDay(for workout: Workout) -> [WorkoutExercise] {
        let e1 = WorkoutExercise(name: "Overhead Press", notes: "5x5, full ROM", repRange: .exact(5), musclesTargeted: [.shoulders, .frontDelt, .triceps], workout: workout)
        e1.sets = ExerciseSet.sampleSet1(for: e1)

        let e2 = WorkoutExercise(name: "Lateral Raise", notes: "4x12–15, controlled tempo", musclesTargeted: [.sideDelt, .shoulders], workout: workout)
        e2.sets = ExerciseSet.sampleSet2(for: e2)

        let e3 = WorkoutExercise(name: "Rear Delt Fly", notes: "3x12–15", repRange: .range(lower: 12, upper: 15), musclesTargeted: [.rearDelt, .shoulders, .rhomboids], workout: workout)
        e3.sets = ExerciseSet.sampleSet3(for: e3)

        let e4 = WorkoutExercise(name: "Upright Row", notes: "3x10", repRange: .exact(10), musclesTargeted: [.upperTraps, .sideDelt, .shoulders, .biceps], workout: workout)
        e4.sets = ExerciseSet.sampleSet4(for: e4)

        return [e1, e2, e3, e4]
    }
    
    static func legDay(for workout: Workout) -> [WorkoutExercise] {
        let e1 = WorkoutExercise(name: "Back Squat", notes: "5x5, belt as needed", musclesTargeted: [.quads, .glutes, .hamstrings], workout: workout)
        e1.sets = ExerciseSet.sampleSet1(for: e1)

        let e2 = WorkoutExercise(name: "Romanian Deadlift", notes: "3x8–10", repRange: .range(lower: 8, upper: 10), musclesTargeted: [.hamstrings, .glutes, .lowerBack], workout: workout)
        e2.sets = ExerciseSet.sampleSet2(for: e2)

        let e3 = WorkoutExercise(name: "Leg Press", notes: "3x12, full lockout optional", repRange: .exact(12), musclesTargeted: [.quads, .glutes], workout: workout)
        e3.sets = ExerciseSet.sampleSet3(for: e3)

        let e4 = WorkoutExercise(name: "Standing Calf Raise", notes: "4x12–15, pause at top", repRange: .range(lower: 12, upper: 15), musclesTargeted: [.calves], workout: workout)
        e4.sets = ExerciseSet.sampleSet4(for: e4)

        return [e1, e2, e3, e4]
    }
    
    static func armDay(for workout: Workout) -> [WorkoutExercise] {
        let e1 = WorkoutExercise(name: "Barbell Curl", notes: "4x10, strict form", repRange: .exact(10), musclesTargeted: [.biceps, .brachialis, .forearms], workout: workout)
        e1.sets = ExerciseSet.sampleSet1(for: e1)

        let e2 = WorkoutExercise(name: "Triceps Pushdown", notes: "4x10–12", repRange: .range(lower: 10, upper: 12), musclesTargeted: [.triceps, .lateralHeadTriceps], workout: workout)
        e2.sets = ExerciseSet.sampleSet2(for: e2)

        let e3 = WorkoutExercise(name: "Hammer Curl", notes: "3x12", musclesTargeted: [.brachialis, .biceps, .forearms], workout: workout)
        e3.sets = ExerciseSet.sampleSet3(for: e3)

        let e4 = WorkoutExercise(name: "Skull Crushers", notes: "3x10", repRange: .exact(10), musclesTargeted: [.triceps, .longHeadTriceps], workout: workout)
        e4.sets = ExerciseSet.sampleSet4(for: e4)

        return [e1, e2, e3, e4]
    }
}
