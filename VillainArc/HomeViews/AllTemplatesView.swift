import SwiftUI
import SwiftData

struct AllTemplatesView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Workout> { workout in
        workout.template
    }, sort: \Workout.startTime, order: .reverse, animation: .smooth) private var templates: [Workout]
    @State private var isEditing = false
    @State private var showDeleteAllAlert = false
    @State private var existingWorkout: Workout? = nil
    
    private func deleteTemplate(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let templateToDelete = templates[index]
                DataManager.shared.deleteWorkout(workout: templateToDelete, context: context)
            }
            HapticManager.instance.impact(style: .light)
        }
    }
    
    private func deleteAllTemplates() {
        withAnimation {
            for template in templates {
                DataManager.shared.deleteWorkout(workout: template, context: context)
            }
        }
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
            List {
                ForEach(templates) { template in
                    Section {
                        NavigationLink(value: template) {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack {
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 0) {
                                        Text(template.title)
                                        Text(exerciseCategories(for: template))
                                            .font(.caption2)
                                            .foregroundStyle(Color.secondary)
                                    }
                                    .fontWeight(.semibold)
                                }
                                .padding(.bottom, 3)
                                ForEach(template.exercises.sorted(by: { $0.order < $1.order})) { exercise in
                                    HStack(spacing: 1) {
                                        Text("\(exercise.sets.count)x")
                                            .foregroundStyle(Color.primary)
                                        Text(exercise.name)
                                            .foregroundStyle(Color.secondary)
                                    }
                                    .lineLimit(1)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .padding(.top, 3)
                                }
                            }
                        }
                        .contextMenu {
                            Button {
                                existingWorkout = template
                            } label: {
                                Label("Use", systemImage: "figure.strengthtraining.traditional")
                            }
                            Button(role: .destructive) {
                                if let index = templates.firstIndex(where: { $0.id == template.id }) {
                                    deleteTemplate(at: IndexSet(integer: index))
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .onDelete(perform: deleteTemplate)
                .listRowBackground(BlurView())
                .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
            .navigationTitle("All Templates")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .navigationBarBackButtonHidden(isEditing)
            .fullScreenCover(item: $existingWorkout) { workout in
                WorkoutView(existingWorkout: workout)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button {
                            showDeleteAllAlert = true
                        } label: {
                            Text("Delete All")
                                .foregroundColor(.red)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !templates.isEmpty {
                        Button {
                            withAnimation {
                                isEditing.toggle()
                            }
                        } label: {
                            Text(isEditing ? "Done" : "Edit")
                        }
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
