import SwiftUI

struct SaveWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @FocusState private var keyboardActive: Bool
    @Binding var title: String
    @Binding var exercises: [TempExercise]
    @Binding var startTime: Date
    @Binding var endTime: Date
    @Binding var notes: String
    var isTemplate: Bool
    var isEditing: Bool
    @State private var originalTitle: String
    @State private var originalStartTime: Date
    @State private var originalEndTime: Date
    @State private var originalNotes: String
    var onSave: () -> Void
    
    init(title: Binding<String>, exercises: Binding<[TempExercise]>, notes: Binding<String>, startTime: Binding<Date>, endTime: Binding<Date>, isTemplate: Bool, isEditing: Bool, onSave: @escaping () -> Void) {
        self._title = title
        self._exercises = exercises
        self._notes = notes
        self._startTime = startTime
        self._endTime = endTime
        self.isTemplate = isTemplate
        self.isEditing = isEditing
        self._originalTitle = State(initialValue: title.wrappedValue)
        self._originalStartTime = State(initialValue: startTime.wrappedValue)
        self._originalEndTime = State(initialValue: endTime.wrappedValue)
        self._originalNotes = State(initialValue: notes.wrappedValue)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                Form {
                    Section {
                        TextField("Workout Title", text: $title)
                            .focused($keyboardActive)
                            .autocorrectionDisabled()
                    } header: {
                        Text("Title")
                            .foregroundStyle(Color.primary)
                            .fontWeight(.semibold)
                    }
                    .listRowBackground(BlurView())
                    if !isTemplate {
                        Section {
                            DatePicker("Start Time", selection: $startTime, in: Date.distantPast...endTime, displayedComponents: [.date, .hourAndMinute])
                            DatePicker("End Time", selection: $endTime, in: startTime...Date() , displayedComponents: [.date, .hourAndMinute])
                        } header: {
                            Text("Time")
                                .foregroundStyle(Color.primary)
                                .fontWeight(.semibold)
                        }
                        .listRowBackground(BlurView())
                    }
                    Section {
                        TextEditor(text: $notes)
                            .focused($keyboardActive)
                            .autocorrectionDisabled()
                    } header: {
                        Text("Notes")
                            .foregroundStyle(Color.primary)
                            .fontWeight(.semibold)
                    }
                    .listRowBackground(BlurView())
                    Section {
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
                    } header: {
                        Text("Exercises")
                            .foregroundStyle(Color.primary)
                            .fontWeight(.semibold)
                    }
                    .listRowBackground(BlurView())
                }
                .scrollContentBackground(.hidden)
                VStack(alignment: .trailing) {
                    Spacer()
                    HStack(alignment: .bottom) {
                        Spacer()
                        if keyboardActive {
                            Button {
                                hideKeyboard()
                                keyboardActive = false
                            } label: {
                                Image(systemName: "keyboard.chevron.compact.down")
                                    .foregroundStyle(Color.primary)
                                    .font(.title)
                            }
                            .buttonStyle(BorderedButtonStyle())
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("\(isEditing ? "Update" : "Save") \(isTemplate ? "Template" : "Workout")")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if !isEditing {
                    endTime = Date()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        startTime = originalStartTime
                        endTime = originalEndTime
                        notes = originalNotes
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onSave()
                        dismiss()
                    } label: {
                        Text(isEditing ? "Update" : "Save")
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                    .disabled(title.isEmpty)
                    .opacity(title.isEmpty ? 0.5 : 1)
                }
            }
        }
    }
}
