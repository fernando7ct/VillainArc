import SwiftUI

enum Tab: String {
    case home = "Home"
    case health = "Health"
    case nutrition = "Nutrition"
    
    var systemImage: String {
        switch self {
        case .home: "house"
        case .health: "heart.text.square.fill"
        case .nutrition: "leaf.fill"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("isSignedIn") var isSignedIn: Bool = false
    @AppStorage("activeTab") var activeTab: Tab = .home
    @State private var homeStack: NavigationPath = .init()
    @State private var healthStack: NavigationPath = .init()
    @State private var nutritionStack: NavigationPath = .init()
    @State private var date: Date = .now.startOfDay
    
    var tabSelection: Binding<Tab> {
        return .init {
            return activeTab
        } set: { newValue in
            if newValue == activeTab {
                switch newValue {
                case .home: 
                    homeStack = .init()
                case .health: healthStack = .init()
                case .nutrition: 
                    if nutritionStack.isEmpty {
                        withAnimation(.snappy) {
                            date = .now.startOfDay
                        }
                    } else {
                        nutritionStack = .init()
                    }
                }
            }
            activeTab = newValue
        }
    }
    
    var body: some View {
        if isSignedIn {
            TabView(selection: tabSelection) {
                NutritionTab(path: $nutritionStack, date: $date)
                    .tabItem {
                        Label(Tab.nutrition.rawValue, systemImage: Tab.nutrition.systemImage)
                    }
                    .tag(Tab.nutrition)
                HomeTab(path: $homeStack)
                    .tabItem {
                        Label(Tab.home.rawValue, systemImage: Tab.home.systemImage)
                    }
                    .tag(Tab.home)
                HealthTab(path: $healthStack)
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
