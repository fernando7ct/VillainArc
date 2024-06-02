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
    return workout.exercises.sorted(by: { $0.order < $1.order }).map { $0.name }.joined(separator: ", ")
}
extension View {
    func customStyle() -> some View {
        self.modifier(CustomStyleModifier())
    }
}
