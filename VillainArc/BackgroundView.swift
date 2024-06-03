import SwiftUI

struct BackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if colorScheme == .light {
            Color("lightBackground")
                .ignoresSafeArea()
                .blur(radius: 150)
        } else {
            RadialGradient(colors: [.black, Color(uiColor: .darkGray)], center: .center, startRadius: 0, endRadius: 600)
                .ignoresSafeArea()
                .blur(radius: 100)
        }
    }
}

#Preview {
    BackgroundView()
}
