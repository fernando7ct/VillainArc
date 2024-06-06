import SwiftUI

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

func formattedWeight(_ weight: Double) -> String {
    let weightInt = Int(weight)
    return weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(weightInt)" : String(format: "%.1f", weight)
}
struct CustomStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding()
            .background(BlurView())
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.vertical, 3)
    }
}
func concatenatedExerciseNames(for workout: Workout) -> String {
    return workout.exercises!.sorted(by: { $0.order < $1.order }).map { $0.name }.joined(separator: ", ")
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
    return "Top Set: \(topSet.reps)x\(formattedWeight(topSet.weight)) lbs"
}
extension View {
    func customStyle() -> some View {
        self.modifier(CustomStyleModifier())
    }
}
