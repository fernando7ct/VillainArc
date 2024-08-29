import SwiftUI
import SwiftData

struct SetStepsGoalView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \HealthSteps.date, order: .reverse) private var steps: [HealthSteps]
    @State private var goal: Int = 0
    @FocusState var fieldFocused: Bool
    
    var todaySteps: HealthSteps? {
        steps.first
    }
    func setProperties() {
        if let todaySteps {
            goal = Int(todaySteps.goal)
        }
    }
    func saveGoal() {
        guard let todaySteps else { return }
        
        if goal == 0 {
            todaySteps.goal = 0
            todaySteps.goalMet = false
        } else {
            todaySteps.goal = Double(goal)
            todaySteps.goalMet = Int(todaySteps.steps) >= goal
        }
        print("Steps Goal Updated")
        print("Steps Goal Complete: \(todaySteps.goalMet)")
        DataManager.shared.saveHealthSteps(healthSteps: todaySteps, context: context, update: true)
        dismiss()
    }
    
    var body: some View {
        NavigationView {
            Form {
                HStack {
                    TextField("Goal", value: $goal, format: .number)
                        .focused($fieldFocused)
                        .keyboardType(.numberPad)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("Goal")
                        .foregroundColor(.gray)
                        .fontWeight(.semibold)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(BlurView())
            }
            .scrollContentBackground(.hidden)
            .background(BackgroundView())
            .navigationTitle("Steps Goal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveGoal()
                    } label: {
                        Text("Save")
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                }
            }
            .onAppear {
                setProperties()
                fieldFocused = true
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
}

#Preview {
    SetStepsGoalView()
}
