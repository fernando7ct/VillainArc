import SwiftUI
import SwiftData

struct WorkoutTab: View {
    @Environment(\.modelContext) private var context
    
    @Namespace private var animation
    
    @Query private var workouts: [Workout]
    @State private var workout: Workout?
    @Query private var exercises: [WorkoutExercise]
    
    var body: some View {
        NavigationStack {
            List {
                Section("Workouts") {
                    ForEach(workouts) { workout in
                        Text(workout.title)
                    }
                }
                Section("Exercise") {
                    Text(exercises.count, format: .number)
                }
            }
            .navigationTitle("Workout")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Start Workout", systemImage: "plus") {
                        startNewWorkout()
                    }
                }
                .matchedTransitionSource(id: "StartWorkout", in: animation)
            }
            .onAppear(perform: checkForUnfinishedWorkout)
            .fullScreenCover(item: $workout) {
                WorkoutView(workout: $0)
                    .navigationTransition(.zoom(sourceID: "StartWorkout", in: animation))
                    .interactiveDismissDisabled()
            }
        }
    }
    
    private func startNewWorkout() {
        let newWorkout = Workout(title: "New Workout")
        context.insert(newWorkout)
        workout = newWorkout
    }
    
    private func checkForUnfinishedWorkout() {
        if let unfinishedWorkout = workouts.first(where: { !$0.completed }) {
            workout = unfinishedWorkout
        }
    }
}

#Preview {
    TabView {
        Tab(Tabs.workout.rawValue, systemImage: Tabs.workout.iconString) {
            WorkoutTab()
                .sampleDataConainer()
        }
    }
}
