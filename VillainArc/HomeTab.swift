import SwiftUI
import SwiftData

struct HomeTab: View {
    @Environment(\.modelContext) private var context
    @Query private var workouts: [Workout] = []
    @State private var workoutStarted: Bool = false
    @State private var creatingTemplate: Bool = false
    
    private func deleteWorkout(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let workoutToDelete = workouts[index]
                DataManager.shared.deleteWorkout(workout: workoutToDelete, context: context)
            }
        }
    }
    private func concatenatedExerciseNames(for workout: Workout) -> String {
        return workout.exercises.sorted(by: { $0.order < $1.order }).map { $0.name }.joined(separator: ", ")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                ScrollView {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Templates")
                                .fontWeight(.semibold)
                                .font(.title2)
                            Spacer()
                            Button(action: {
                                creatingTemplate.toggle()
                            }, label: {
                                Image(systemName: "plus")
                            })
                            .fullScreenCover(isPresented: $creatingTemplate) {
                                TemplateView()
                            }
                            .padding(.trailing)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                        ForEach(workouts, id: \.self) { workout in
                            NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(workout.title)
                                            .fontWeight(.semibold)
                                        Text(concatenatedExerciseNames(for: workout))
                                            .lineLimit(2)
                                            .font(.subheadline)
                                            .foregroundStyle(Color.secondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(BlurView())
                                .cornerRadius(12)
                                .padding(.horizontal)
                                .padding(.vertical, 3)
                            }
                        }
                        HStack {
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 5)
                    }
                    .padding(.top)
//                    Section {
//                        Button(action: {
//                            workoutStarted.toggle()
//                        }, label: {
//                            Text("Workout")
//                        })
//                        .fullScreenCover(isPresented: $workoutStarted) {
//                            WorkoutView()
//                        }
//                    }
                }
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeTab()
}
