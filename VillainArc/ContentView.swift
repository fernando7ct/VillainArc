import SwiftUI

struct ContentView: View {
    @AppStorage("isSignedIn") var isSignedIn = false
    @State private var selection = 1
    
    var body: some View {
        if isSignedIn {
            TabView(selection: $selection) {
                HealthTab()
                    .tabItem {
                        Label("Health", systemImage: "heart.text.square.fill")
                    }
                    .tag(0)
                HomeTab()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(1)
                WeightTab()
                    .tabItem {
                        Label("Weight", systemImage: "scalemass.fill")
                    }
                    .tag(2)
            }
            .tint(Color.primary)
        } else {
            LogInView()
        }
    }
}

#Preview {
    ContentView()
}
