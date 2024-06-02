import SwiftUI
import SwiftData

struct AllTemplatesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Workout.startTime, order: .reverse) private var workouts: [Workout]
    @State private var isEditing = false
    @State private var showDeleteAllAlert = false
    
    private func deleteTemplate(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let templateToDelete = workouts.filter { $0.template }[index]
                DataManager.shared.deleteWorkout(workout: templateToDelete, context: context)
            }
        }
    }
    
    private func deleteAllTemplates() {
        withAnimation {
            for template in workouts.filter({ $0.template }) {
                DataManager.shared.deleteWorkout(workout: template, context: context)
            }
            isEditing.toggle()
        }
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
            List {
                ForEach(workouts.filter { $0.template }, id: \.self) { workout in
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
                    }
                }
                .onDelete(perform: deleteTemplate)
                .listRowBackground(BlurView())
            }
            .scrollContentBackground(.hidden)
            .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
            .overlay {
                if workouts.filter({ $0.template }).isEmpty {
                    ContentUnavailableView("You have no templates.", systemImage: "doc.text")
                }
            }
            .navigationTitle("All Templates")
            .navigationBarBackButtonHidden(isEditing && !workouts.filter({ $0.template }).isEmpty)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing && !workouts.filter({ $0.template }).isEmpty {
                        Button(action: {
                            showDeleteAllAlert = true
                        }, label: {
                            Text("Delete All")
                                .foregroundColor(.red)
                        })
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !workouts.filter({ $0.template }).isEmpty {
                        Button(action: {
                            withAnimation {
                                isEditing.toggle()
                            }
                        }, label: {
                            Text(isEditing ? "Done" : "Edit")
                        })
                    }
                }
            }
            .alert(isPresented: $showDeleteAllAlert) {
                Alert(
                    title: Text("Delete All Templates"),
                    message: Text("Are you sure you want to delete all templates?"),
                    primaryButton: .destructive(Text("Delete All")) {
                        deleteAllTemplates()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

#Preview {
    AllTemplatesView()
}
