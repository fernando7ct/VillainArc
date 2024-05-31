import SwiftUI

struct ExerciseView: View {
    @Binding var exercise: TempExercise
    @FocusState private var keyboardActive: Bool
    @FocusState private var notesFocused: Bool
    
    private func deleteSet(at offsets: IndexSet) {
        withAnimation {
            exercise.sets.remove(atOffsets: offsets)
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(exercise.name)
                            .font(.title)
                            .fontWeight(.semibold)
                        Text(exercise.category)
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                        
                    }
                    Spacer()
                }
                .padding(.horizontal)
                List {
                    Section {
                        ZStack(alignment: .leading) {
                            TextEditor(text: $exercise.notes)
                                .focused($notesFocused)
                            if !notesFocused && exercise.notes.isEmpty {
                                Text("Notes...")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                                    .onTapGesture {
                                        notesFocused = true
                                    }
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    
                    Section {
                        if !exercise.sets.isEmpty {
                            HStack {
                                Text("Set")
                                    .offset(x: 5)
                                Text("Reps")
                                    .offset(x: 30)
                                Text("Weight")
                                    .offset(x: 130)
                            }
                            .fontWeight(.semibold)
                        }
                        ForEach(exercise.sets.indices, id: \.self) { setIndex in
                            HStack {
                                Text("\(setIndex + 1)")
                                    .padding(.horizontal)
                                    .padding(.vertical, 7)
                                    .background {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(Color(uiColor: UIColor.secondarySystemBackground))
                                    }
                                TextField("", value: $exercise.sets[setIndex].reps, format: .number)
                                    .keyboardType(.numberPad)
                                    .padding(.horizontal)
                                    .padding(.vertical, 7)
                                    .background {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(Color(uiColor: UIColor.secondarySystemBackground))
                                    }
                                    .focused($keyboardActive)
                                TextField("", value: $exercise.sets[setIndex].weight, format: .number)
                                    .keyboardType(.decimalPad)
                                    .padding(.horizontal)
                                    .padding(.vertical, 7)
                                    .background {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(Color(uiColor: UIColor.secondarySystemBackground))
                                    }
                                    .focused($keyboardActive)
                                Button(action: {
                                    exercise.sets[setIndex].completed.toggle()
                                }, label: {
                                    Image(systemName: "checkmark.square.fill")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(exercise.sets[setIndex].completed ? .green : .white, Color(uiColor: UIColor.secondarySystemBackground))
                                        .font(.system(size: 40))
                                })
                            }
                            .font(.title2)
                        }
                        .onDelete(perform: deleteSet)
                    }
                    .listRowSeparator(.hidden)
                    
                    Section {
                        Button(action: {
                            exercise.sets.append(TempSet(reps: 0, weight: 0, completed: false))
                        }, label: {
                            HStack {
                                Label("Add Set", systemImage: "plus")
                                Spacer()
                            }
                            .padding(.vertical, 5)
                            .foregroundStyle(Color.primary)
                        })
                        .buttonStyle(BorderedButtonStyle())
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
            VStack(alignment: .trailing) {
                Spacer()
                HStack(alignment: .bottom) {
                    Spacer()
                    if keyboardActive || notesFocused {
                        Button(action: {
                            hideKeyboard()
                            keyboardActive = false
                            notesFocused = false
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
    }
}

//#Preview {
//    ExerciseView()
//}
