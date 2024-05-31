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
            .foregroundColor(Color.primary)
            .padding()
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(uiColor: UIColor.secondarySystemBackground).shadow(.drop(radius: 2)))
            }
            
    }
}

extension View {
    func customStyle() -> some View {
        self.modifier(CustomStyleModifier())
    }
}
