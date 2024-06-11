import SwiftUI
import SwiftData

struct HealthTab: View {
    @AppStorage("activeCalories") var activeCalories: Double = 0
    @AppStorage("restingCalories") var restingCalories: Double = 0
    @AppStorage("todaysSteps") var todaysSteps: Double = 0
    @AppStorage("healthAccess") var healthAccess = false
    @Environment(\.modelContext) private var context
    
    private func getTodaysData() {
        HealthManager.shared.fetchTodaySteps { todaySteps in
            todaysSteps = todaySteps
        }
        HealthManager.shared.fetchTodayActiveEnergy { activeEnergy in
            activeCalories = activeEnergy
        }
        HealthManager.shared.fetchTodayRestingEnergy { restingEnergy in
            restingCalories = restingEnergy
        }
    }
    private func update() {
        HealthManager.shared.accessGranted(context: context) { success in
            if !success {
                healthAccess = false
            } else {
                HealthManager.shared.fetchSteps(context: context)
                HealthManager.shared.fetchActiveEnergy(context: context)
                HealthManager.shared.fetchRestingEnergy(context: context)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                if healthAccess {
                    ScrollView {
                        StepsSectionView(todaysSteps: $todaysSteps)
                        CaloriesSectionView(activeCalories: $activeCalories, restingCalories: $restingCalories)
                    }
                    .onAppear {
                        update()
                        getTodaysData()
                    }
                    .navigationTitle("Health")
                    .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                    .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                } else {
                    unavailableView
                }
            }
        }
    }
    
    var unavailableView: some View {
        ContentUnavailableView(label: {
            Label("Health Access", systemImage: "heart.text.square.fill")
        }, description: {
            Text("You haven't allowed access to health data.")
        }, actions: {
            Button(action: {
                HealthManager.shared.requestHealthData { granted in
                    if granted {
                        HealthManager.shared.accessGranted(context: context) { success in
                            if success {
                                HealthManager.shared.fetchSteps(context: context)
                                HealthManager.shared.fetchActiveEnergy(context: context)
                                HealthManager.shared.fetchRestingEnergy(context: context)
                                healthAccess = true
                            }
                        }
                    }
                }
            }) {
                Text("Update Access")
                    .fontWeight(.semibold)
            }
        })
    }
}

#Preview {
    HealthTab()
}
