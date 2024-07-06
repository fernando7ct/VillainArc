import SwiftUI

struct HealthTab: View {
    @AppStorage("healthAccess") var healthAccess = false
    @Environment(\.modelContext) private var context
    @StateObject var healthManager = HealthManager.shared
    @State private var scrollPosition = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: Date()))!
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                if healthAccess {
                    ScrollView {
                        WeightSectionView()
                        StepsSectionView(todaysSteps: healthManager.todaysSteps, todaysDistance: healthManager.todaysWalkingRunningDistance)
                        CaloriesSectionView(activeCalories: healthManager.todaysActiveCalories, restingCalories: healthManager.todaysRestingCalories)
                    }
                    .onAppear {
                        Task {
                            await healthManager.fetchAndUpdateAllData(context: context)
                        }
                    }
                    .navigationTitle(Tab.health.rawValue)
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
                healthManager.requestHealthData { granted in
                    if granted {
                        healthManager.accessGranted { success in
                            if success {
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
