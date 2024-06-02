import SwiftUI

struct WorkoutDetailView: View {
    @State var workout: Workout
    @State private var workoutStarted: Bool = false
    
    private func totalWorkoutTime(startTime: Date, endTime: Date) -> String {
        let timeInterval = endTime.timeIntervalSince(startTime)
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(workout.title)
                            .font(.title)
                            .fontWeight(.semibold)
                        Text("\(workout.template ? "Created: " : "" )\(workout.startTime.formatted(.dateTime.month().day().year().weekday(.wide)))")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                        if !workout.template {
                            Text("Total Time: \(totalWorkoutTime(startTime: workout.startTime, endTime: workout.endTime))")
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    Spacer()
                    Menu {
                        Button(action: {
                            workoutStarted.toggle()
                        }, label: {
                            Label(workout.template ? "Use Template" : "Use as Template", systemImage: "doc.text")
                        })
                    } label: {
                        Image(systemName: "chevron.down.circle")
                            .font(.title)
                            .foregroundStyle(Color.primary)
                    }
                    .fullScreenCover(isPresented: $workoutStarted) {
                        WorkoutView(existingWorkout: workout)
                    }
                }
                .padding([.horizontal, .bottom])
                if !workout.template {
                    List {
                        if !workout.notes.isEmpty {
                            Section(content: {
                                Text(workout.notes)
                            }, header: {
                                Text("Notes")
                            })
                            .listRowBackground(BlurView())
                        }
                        ForEach(workout.exercises.sorted(by: { $0.order < $1.order}), id: \.self) { exercise in
                            
                            Section(content: {
                                ForEach(exercise.sets.sorted(by: { $0.order < $1.order}), id: \.self) { set in
                                    HStack {
                                        Text("Set: \(set.order + 1)")
                                        Spacer()
                                        Text("Reps: \(set.reps)")
                                        Spacer()
                                        Text("Weight: \(formattedWeight(set.weight)) lbs")
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
                            .listRowBackground(BlurView())
                        }
                    }
                    .scrollContentBackground(.hidden)
                } else {
                    List {
                        if !workout.notes.isEmpty {
                            Section {
                                Text("Notes: \(workout.notes)")
                            }
                        }
                        Section {
                            ForEach(workout.exercises.sorted(by: { $0.order < $1.order}), id: \.self) { exercise in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(exercise.name)
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                        Text(exercise.category)
                                            .font(.subheadline)
                                            .foregroundStyle(Color.secondary)
                                        Text("\(exercise.sets.count) \(exercise.sets.count == 1 ? "set" : "sets")")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.secondary)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
