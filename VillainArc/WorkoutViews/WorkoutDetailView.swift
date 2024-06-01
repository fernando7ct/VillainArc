import SwiftUI

struct WorkoutDetailView: View {
    @State var workout: Workout
    @State private var workoutStarted: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(workout.title)
                        .font(.title)
                        .fontWeight(.semibold)
                    Text("\(workout.startTime.formatted(.dateTime.month().day().year()))")
                }
                Spacer()
                Menu {
                    Button(action: {
                        workoutStarted.toggle()
                    }, label: {
                        Label("Use as Template", systemImage: "doc.text")
                    })
                } label: {
                    Image(systemName: "chevron.down.circle")
                        .font(.title)
                        .foregroundStyle(Color.primary)
                }
                .fullScreenCover(isPresented: $workoutStarted) {
                    WorkoutView(exisistingWorkout: workout)
                }
            }
            .padding([.horizontal, .bottom])
            
            List {
                Section("Notes") {
                    if workout.notes.isEmpty {
                        Text("No workout notes")
                    } else {
                        Text(workout.notes)
                    } 
                }
                ForEach(workout.exercises.sorted(by: { $0.order < $1.order}), id: \.self) { exercise in
                    Section(content: {
                        ForEach(exercise.sets.sorted(by: { $0.order < $1.order}), id: \.self) { set in
                            HStack {
                                Text("Set: \(set.order + 1)")
                                Spacer()
                                Text("Reps: \(set.reps)")
                                Spacer()
                                Text("Weight \(set.weight)")
                            }
                        }

                    }, header: {
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                            if !exercise.notes.isEmpty {
                                Text("Notes: \(exercise.notes)")
                            }
                        }
                    })
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
