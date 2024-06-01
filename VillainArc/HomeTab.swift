import SwiftUI
import SwiftData

struct HomeTab: View {
    @Environment(\.modelContext) private var context
    @Query private var workouts: [Workout]
    @State private var workoutStarted: Bool = false
    
    private func deleteWorkout(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let workoutToDelete = workouts[index]
                DataManager.shared.deleteWorkout(workout: workoutToDelete, context: context)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(workouts, id: \.self) { workout in
                        NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                            HStack {
                                Text(workout.title)
                            }
                        }
                    }
                    .onDelete(perform: deleteWorkout)
                }
                Section {
                    Button(action: {
                        workoutStarted.toggle()
                    }, label: {
                        Text("Workout")
                    })
                    .fullScreenCover(isPresented: $workoutStarted) {
                        WorkoutView()
                    }
                }
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeTab()
}
