import SwiftUI

enum Tab: String {
    case home = "Home"
    case health = "Health"
    case nutrition = "Nutrition"
    
    var systemImage: String {
        switch self {
        case .home:
            return "house"
        case .health:
            return "heart.text.square.fill"
        case .nutrition:
            return "leaf.fill"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("isSignedIn") var isSignedIn = false
    @State private var activeTab: Tab = .home

    var body: some View {
        if isSignedIn {
            TabView(selection: $activeTab) {
                NutritionTab()
                    .tabItem {
                        Label(Tab.nutrition.rawValue, systemImage: Tab.nutrition.systemImage)
                    }
                    .tag(Tab.nutrition)
                HomeTab()
                    .tabItem {
                        Label(Tab.home.rawValue, systemImage: Tab.home.systemImage)
                    }
                    .tag(Tab.home)
                HealthTab()
                    .tabItem {
                        Label(Tab.health.rawValue, systemImage: Tab.health.systemImage)
                    }
                    .tag(Tab.health)
            }
            .tint(Color.primary)
            .onAppear {
                DataManager.shared.checkUserDataComplete { success in
                    if !success {
                        DataManager.shared.deleteDataAndSignOut(context: context)
                    }
                }
            }
        } else {
            LogInView()
        }
    }
}

#Preview {
    ContentView()
}
