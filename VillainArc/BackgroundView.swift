import SwiftUI

struct BackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if colorScheme == .light {
            RadialGradient(colors: [.white, Color(uiColor: .lightGray)], center: .center, startRadius: 0, endRadius: 250)
            //Image("lightBackground")
                //.resizable()
                //.scaledToFit()
                .ignoresSafeArea()
                .blur(radius: 150)
        } else {
            RadialGradient(colors: [.black, Color(uiColor: .darkGray)], center: .center, startRadius: 0, endRadius: 600)
            //Image("darkBackground")
                //.resizable()
                //.scaledToFit()
                .ignoresSafeArea()
                .blur(radius: 100)
        }
    }
}

#Preview {
    BackgroundView()
}
