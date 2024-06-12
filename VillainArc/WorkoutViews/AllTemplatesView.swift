import SwiftUI
import SwiftData

struct AllTemplatesView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Workout> { workout in
        workout.template
    }, sort: \Workout.startTime, order: .reverse, animation: .smooth) private var templates: [Workout]
    @State private var isEditing = false
    @State private var showDeleteAllAlert = false
    
    private func deleteTemplate(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let templateToDelete = templates[index]
                DataManager.shared.deleteWorkout(workout: templateToDelete, context: context)
            }
        }
    }
    
    private func deleteAllTemplates() {
        withAnimation {
            for template in templates {
                DataManager.shared.deleteWorkout(workout: template, context: context)
            }
            isEditing.toggle()
        }
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
            List {
                ForEach(templates) { template in
                    NavigationLink(destination: WorkoutDetailView(workout: template)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(template.title)
                                    .fontWeight(.semibold)
                                Text(concatenatedExerciseNames(for: template))
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
                if templates.isEmpty {
                    ContentUnavailableView("You have no templates.", systemImage: "doc.text")
                }
            }
            .navigationTitle("All Templates")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .navigationBarBackButtonHidden(isEditing && !templates.isEmpty)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing && !templates.isEmpty {
                        Button(action: {
                            showDeleteAllAlert = true
                        }, label: {
                            Text("Delete All")
                                .foregroundColor(.red)
                        })
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !templates.isEmpty {
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
