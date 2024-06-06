import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @State var workout: Workout
    @State private var workoutStarted: Bool = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var showDeleteAlert = false
    
    private func totalWorkoutTime(startTime: Date, endTime: Date) -> String {
        let timeInterval = endTime.timeIntervalSince(startTime)
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    private func deleteWorkout() {
        withAnimation {
            DataManager.shared.deleteWorkout(workout: workout, context: context)
            dismiss()
        }
    }
    private func saveWorkoutAsTemplate() {
        withAnimation {
            DataManager.shared.saveWorkoutAsTemplate(workout: workout, context: context)
        }
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
                }
                .padding([.horizontal, .bottom])
                if !workout.template {
                    List {
                        if !workout.notes.isEmpty {
                            Section(content: {
                                Text(workout.notes)
                            }, header: {
                                Text("Notes")
                                    .foregroundStyle(Color.primary)
                                    .fontWeight(.semibold)
                            })
                            .listRowBackground(BlurView())
                        }
                        ForEach(workout.exercises!.sorted(by: { $0.order < $1.order})) { exercise in
                            Section(content: {
                                ForEach(exercise.sets!.sorted(by: { $0.order < $1.order})) { set in
                                    HStack {
                                        Text("Set: \(set.order + 1)")
                                        Spacer()
                                        Text("Reps: \(set.reps)")
                                        Spacer()
                                        Text("Weight: \(formattedWeight(set.weight)) lbs")
                                    }
                                }
                                .listRowSeparator(.hidden)
                            }, header: {
                                VStack(alignment: .leading) {
                                    Text(exercise.name)
                                        .foregroundStyle(Color.primary)
                                        .fontWeight(.semibold)
                                    if !exercise.notes.isEmpty {
                                        Text("Notes: \(exercise.notes)")
                                            .lineLimit(2)
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
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        Section {
                            ForEach(workout.exercises!.sorted(by: { $0.order < $1.order})) { exercise in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(exercise.name)
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color.primary)
                                        if !exercise.notes.isEmpty {
                                            Text("Notes: \(exercise.notes.trimmingCharacters(in: .whitespacesAndNewlines))")
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                        }
                                        Text(exercise.category)
                                        Text("\(exercise.sets!.count) \(exercise.sets!.count == 1 ? "set" : "sets")")
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                                    Spacer()
                                }
                                .listRowSeparator(.hidden)
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Delete \(workout.template ? "Template" : "Workout")"),
                    message: Text("Are you sure you want to delete this \(workout.template ? "template" : "workout")?"),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteWorkout()
                    },
                    secondaryButton: .cancel()
                )
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if !workout.template {
                            Button(action: {
                                saveWorkoutAsTemplate()
                                dismiss()
                            }, label: {
                                Label("Make into Template", systemImage: "doc.text")
                            })
                        }
                        Button(action: {
                            workoutStarted.toggle()
                        }, label: {
                            Label("Use \(workout.template ? "" : "as ")Template", systemImage: "doc.text")
                        })
                        Button(action: {
                            showDeleteAlert = true
                        }, label: {
                            Label("Delete \(workout.template ? "Template" : "Workout")", systemImage: "trash")
                        })
                    } label: {
                        Image(systemName: "chevron.down.circle")
                            .font(.title2)
                    }
                    .fullScreenCover(isPresented: $workoutStarted) {
                        WorkoutView(existingWorkout: workout)
                    }
                }
            }
        }
    }
}
