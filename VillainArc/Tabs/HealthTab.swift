import SwiftUI

struct HealthTab: View {
    @AppStorage("healthAccess") var healthAccess = false
    @Environment(\.modelContext) private var context
    @StateObject var healthManager = HealthManager.shared
    @Binding var path: NavigationPath
    
    var body: some View {
        NavigationStack(path: $path) {
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
            .navigationDestination(for: Int.self) { int in
                if int == 0 {
                    WeightView()
                } else if int == 1 {
                    StepsView()
                } else if int == 2 {
                    CaloriesView()
                } else if int == 3 {
                    AllWeightEntriesView()
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
            Button {
                healthManager.requestHealthData { granted in
                    if granted {
                        healthManager.accessGranted { success in
                            if success {
                                healthAccess = true
                            }
                        }
                    }
                }
            } label:  {
                Text("Update Access")
                    .fontWeight(.semibold)
            }
        })
    }
}
