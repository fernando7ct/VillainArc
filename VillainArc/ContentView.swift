import SwiftUI

enum Tab: String {
    case home = "Home"
    case workout = "Workout"
    case health = "Health"
    case nutrition = "Nutrition"
    
    var systemImage: String {
        switch self {
        case .home:
            return "house"
        case .workout:
            return "figure.strengthtraining.traditional"
        case .health:
            return "heart.text.square.fill"
        case .nutrition:
            return "leaf.fill"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("isSignedIn") var isSignedIn: Bool = false
    @State private var activeTab: Tab = .home
    @State private var homeStack: NavigationPath = .init()
    @State private var healthStack: NavigationPath = .init()
    @State private var nutritionStack: NavigationPath = .init()
    @State private var workoutStack: NavigationPath = .init()
    @State private var selectedDate: Date = .now.startOfDay
    
    var tabSelection: Binding<Tab> {
        return .init {
            return activeTab
        } set: { newValue in
            if newValue == activeTab {
                switch newValue {
                case .home:
                    if homeStack.isEmpty {
                        selectedDate = .now.startOfDay
                    } else {
                        homeStack = .init()
                    }
                case .workout:
                    workoutStack = .init()
                case .health:
                    healthStack = .init()
                case .nutrition:
                    nutritionStack = .init()
                }
            }
            activeTab = newValue
        }
    }
    
    var body: some View {
        if isSignedIn {
            TabView(selection: tabSelection) {
                NutritionTab(path: $nutritionStack)
                    .tabItem {
                        Label(Tab.nutrition.rawValue, systemImage: Tab.nutrition.systemImage)
                    }
                    .tag(Tab.nutrition)
                HomeTab(selectedDate: $selectedDate, path: $homeStack)
                    .tabItem {
                        Label(Tab.home.rawValue, systemImage: Tab.home.systemImage)
                    }
                    .tag(Tab.home)
                WorkoutTab(path: $workoutStack)
                    .tabItem {
                        Label(Tab.workout.rawValue, systemImage: Tab.workout.systemImage)
                    }
                    .tag(Tab.workout)
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
