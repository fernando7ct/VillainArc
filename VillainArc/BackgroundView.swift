import SwiftUI

struct BackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if colorScheme == .light {
            Color("lightBackground")
                .ignoresSafeArea()
                .blur(radius: 225)
        } else {
            RadialGradient(colors: [.black, Color(uiColor: .darkGray)], center: .center, startRadius: 0, endRadius: 600)
                .ignoresSafeArea()
                .blur(radius: 100)
        }
    }
}
struct BlurView: UIViewRepresentable, View {
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        return view
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
#Preview {
    BackgroundView()
}
