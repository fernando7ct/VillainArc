import SwiftUI

enum Tab: String {
    case home = "Home"
    case health = "Health"
    case weight = "Weight"
    
    var systemImage: String {
        switch self {
        case .home:
            return "house"
        case .health:
            return "heart.text.square.fill"
        case .weight:
            return "scalemass.fill"
        }
    }
}

struct ContentView: View {
    @AppStorage("isSignedIn") var isSignedIn = false
    @State private var activeTab: Tab = .home

    var body: some View {
        if isSignedIn {
            TabView(selection: $activeTab) {
                HealthTab()
                    .tabItem {
                        Label(Tab.health.rawValue, systemImage: Tab.health.systemImage)
                    }
                    .tag(Tab.health)
                HomeTab()
                    .tabItem {
                        Label(Tab.home.rawValue, systemImage: Tab.home.systemImage)
                    }
                    .tag(Tab.home)
                WeightTab()
                    .tabItem {
                        Label(Tab.weight.rawValue, systemImage: Tab.weight.systemImage)
                    }
                    .tag(Tab.weight)
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
