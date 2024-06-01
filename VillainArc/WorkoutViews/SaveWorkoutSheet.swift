import SwiftUI

struct SaveWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Binding var exercises: [TempExercise]
    @Binding var startTime: Date
    @Binding var endTime: Date
    @Binding var notes: String
    @Binding var isTemplate: Bool
    @State private var editableTitle: String
    @State private var originalStartTime: Date
    @State private var originalEndTime: Date
    @State private var originalNotes: String
    @State private var originalIsTemplate: Bool
    var onSave: (String) -> Void
    
    init(title: String, exercises: Binding<[TempExercise]>, notes: Binding<String>, startTime: Binding<Date>, endTime: Binding<Date>, isTemplate: Binding<Bool>, onSave: @escaping (String) -> Void) {
        self._editableTitle = State(initialValue: title)
        self._exercises = exercises
        self._notes = notes
        self._startTime = startTime
        self._endTime = endTime
        self._isTemplate = isTemplate
        self._originalStartTime = State(initialValue: startTime.wrappedValue)
        self._originalEndTime = State(initialValue: endTime.wrappedValue)
        self._originalNotes = State(initialValue: notes.wrappedValue)
        self._originalIsTemplate = State(initialValue: isTemplate.wrappedValue)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(content: {
                    TextField("Workout Title", text: $editableTitle)
                }, header: {
                    Text("Title")
                })
                if !originalIsTemplate {
                    Section(content: {
                        Toggle("Save as Template?", isOn: $isTemplate)
                    }, header: {
                        Text("Template")
                    })
                    Section(content: {
                        DatePicker("Start Time", selection: $startTime, in: Date.distantPast...endTime, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("End Time", selection: $endTime, in: startTime...Date() , displayedComponents: [.date, .hourAndMinute])
                    }, header: {
                        Text("Time")
                    })
                }
                Section(content: {
                    TextEditor(text: $notes)
                }, header: {
                    Text("Notes")
                })
                Section(content: {
                    ForEach(exercises) { exercise in
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(exercise.category)
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                            Text("\(exercise.sets.count) \(exercise.sets.count == 1 ? "set" : "sets")")
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                        }
                        .foregroundStyle(Color.primary)
                    }
                }, header: {
                    Text("Exercises")
                })
            }
            .navigationTitle(originalIsTemplate ? "Save Template" : "Save Workout")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                endTime = Date()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        startTime = originalStartTime
                        endTime = originalEndTime
                        notes = originalNotes
                        isTemplate = originalIsTemplate
                        dismiss()
                    }, label: {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                    })
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        onSave(editableTitle)
                        dismiss()
                    }, label: {
                        Text("Save")
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    })
                }
            }
        }
    }
}
