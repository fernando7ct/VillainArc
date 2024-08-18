import SwiftUI

struct BackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if colorScheme == .light {
            Color.white
        } else {
            RadialGradient(colors: [.black, Color(uiColor: .darkGray)], center: .center, startRadius: 0, endRadius: 600)
                .ignoresSafeArea()
        }
    }
}
struct BlurView: UIViewRepresentable, View {
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        return view
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
struct CustomStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding()
            .background(.thickMaterial, in: .rect(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.vertical, 3)
    }
}
extension View {
    func customStyle() -> some View {
        self.modifier(CustomStyleModifier())
    }
}
#Preview {
    BackgroundView()
}
