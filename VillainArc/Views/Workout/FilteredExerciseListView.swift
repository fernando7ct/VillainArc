import SwiftUI
import SwiftData

struct FilteredExerciseListView: View {
    @Query private var exercises: [Exercise]
    @Binding var selectedExercises: [Exercise]
    
    init(exerciseName: String = "", selectedExercises: Binding<[Exercise]>) {
        let predicate = #Predicate<Exercise> { exercise in
            exerciseName.isEmpty || exercise.name.localizedStandardContains(exerciseName)
        }
        _exercises = Query(filter: predicate, sort: \.name)
        _selectedExercises = selectedExercises
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(exercises) { exercise in
                    Group {
                        if selectedExercises.contains(exercise) {
                            Button {
                                selectedExercises.removeAll(where: { $0.id == exercise.id })
                            } label: {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(exercise.name)
                                        .font(.headline)
                                    Text(exercise.musclesTargeted.filter({ $0.isMajor }).map({ $0.rawValue }), format: .list(type: .and))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(5)
                            }
                            .buttonStyle(.glassProminent)
                            .tint(.blue.opacity(0.7))
                        } else {
                            Button {
                                selectedExercises.append(exercise)
                            } label: {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(exercise.name)
                                        .font(.headline)
                                    Text(exercise.musclesTargeted.filter({ $0.isMajor }).map({ $0.rawValue }), format: .list(type: .and))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(5)
                            }
                            .buttonStyle(.glass)
                        }
                    }
                    .tint(.primary)
                    .buttonBorderShape(.roundedRectangle)
                    .padding(.horizontal, 10)
                }
            }
        }
        .animation(.bouncy, value: exercises)
        .animation(.bouncy, value: selectedExercises)
//        List {
//            ForEach(exercises) { exercise in
//                Button {
//                    if selectedExercises.contains(exercise) {
//                        selectedExercises.removeAll(where: { $0.id == exercise.id })
//                    } else {
//                        selectedExercises.append(exercise)
//                    }
//                } label: {
//                    VStack(alignment: .leading, spacing: 0) {
//                        Text(exercise.name)
//                            .font(.headline)
//                        Text(exercise.musclesTargeted.filter({ $0.isMajor }).map({ $0.rawValue }), format: .list(type: .and))
//                            .font(.subheadline)
//                            .foregroundStyle(.secondary)
//                    }
//                }
//                .tint(.primary)
//                .listRowBackground(selectedExercises.contains(exercise) ? Color.blue.opacity(0.3) : nil)
//            }
//        }
    }
}

#Preview {
    AddExerciseView(workout: Workout.sampleData.first!)
        .sampleDataConainer()
}
