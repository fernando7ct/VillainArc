import SwiftUI

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

func formattedDouble(_ weight: Double) -> String {
    let weightInt = Int(weight)
    return weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(weightInt)" : String(format: "%.1f", weight)
}
func exerciseCategories(for workout: Workout) -> String {
    guard let exercises = workout.exercises else { return "" }
    let categories = Set(exercises.map { $0.category })
    return categories.joined(separator: ", ")
}
func topSet(for exerciseInfo: ExerciseInfo) -> String {
    guard let topSet = exerciseInfo.sets.max(by: {
        if $0.weight == $1.weight {
            return $0.reps < $1.reps
        } else {
            return $0.weight < $1.weight
        }
    }) else {
        return "No sets"
    }
    return "Top Set: \(topSet.reps)x\(formattedDouble(topSet.weight)) lbs"
}

