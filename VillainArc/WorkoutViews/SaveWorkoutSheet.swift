import SwiftUI

struct SaveWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @FocusState private var keyboardActive: Bool
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
            ZStack {
                BackgroundView()
                Form {
                    Section(content: {
                        TextField("Workout Title", text: $editableTitle)
                            .focused($keyboardActive)
                            .autocorrectionDisabled()
                    }, header: {
                        Text("Title")
                            .foregroundStyle(Color.primary)
                            .fontWeight(.semibold)
                    })
                    .listRowBackground(BlurView())
                    if !originalIsTemplate {
                        Section(content: {
                            DatePicker("Start Time", selection: $startTime, in: Date.distantPast...endTime, displayedComponents: [.date, .hourAndMinute])
                            DatePicker("End Time", selection: $endTime, in: startTime...Date() , displayedComponents: [.date, .hourAndMinute])
                        }, header: {
                            Text("Time")
                                .foregroundStyle(Color.primary)
                                .fontWeight(.semibold)
                        })
                        .listRowBackground(BlurView())
                    }
                    Section(content: {
                        TextEditor(text: $notes)
                            .focused($keyboardActive)
                            .autocorrectionDisabled()
                    }, header: {
                        Text("Notes")
                            .foregroundStyle(Color.primary)
                            .fontWeight(.semibold)
                    })
                    .listRowBackground(BlurView())
                    Section(content: {
                        ForEach(exercises) { exercise in
                            VStack(alignment: .leading) {
                                Text(exercise.name)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.primary)
                                if !exercise.notes.isEmpty {
                                    Text("Notes: \(exercise.notes.trimmingCharacters(in: .whitespacesAndNewlines))")
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                                Text(exercise.category)
                                Text("\(exercise.sets.count) \(exercise.sets.count == 1 ? "set" : "sets")")
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                        }
                    }, header: {
                        Text("Exercises")
                            .foregroundStyle(Color.primary)
                            .fontWeight(.semibold)
                    })
                    .listRowBackground(BlurView())
                }
                .scrollContentBackground(.hidden)
                VStack(alignment: .trailing) {
                    Spacer()
                    HStack(alignment: .bottom) {
                        Spacer()
                        if keyboardActive {
                            Button(action: {
                                hideKeyboard()
                                keyboardActive = false
                            }, label: {
                                Image(systemName: "keyboard.chevron.compact.down")
                                    .foregroundStyle(Color.primary)
                                    .font(.title)
                            })
                            .buttonStyle(BorderedButtonStyle())
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(originalIsTemplate ? "Save Template" : "Save Workout")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
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
