import SwiftUI
import SwiftData

struct HealthTab: View {
    @AppStorage("healthAccess") var healthAccess = false
    @Environment(\.modelContext) private var context
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                if healthAccess {
                    ScrollView {
                        StepsSectionView()
                    }
                    .navigationTitle("Health")
                    .onAppear {
                        fetchStepsAndDisplay()
                    }
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
                        HealthManager.shared.accessGranted { success in
                            if success {
                                HealthManager.shared.fetchSteps(context: context)
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
    func fetchStepsAndDisplay() {
        HealthManager.shared.accessGranted { success in
            if success {
                HealthManager.shared.fetchSteps(context: context)
            } else {
                healthAccess = false
            }
        }
    }
}

#Preview {
    HealthTab()
}