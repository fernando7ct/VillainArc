import SwiftUI

struct ContentView: View {
    @AppStorage("isSignedIn") var isSignedIn = false
    
    var body: some View {
        if isSignedIn {
            TabView {
                HomeTab()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                WeightTab()
                    .tabItem {
                        Label("Weight", systemImage: "scalemass.fill")
                    }
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
