import SwiftUI

struct TemplateExerciseView: View {
    @Binding var exercise: TempExercise
    @FocusState private var keyboardActive: Bool
    @FocusState private var notesFocused: Bool
    @State private var setRepRangeSheet = false
    
    private func deleteSet(at offsets: IndexSet) {
        withAnimation {
            exercise.sets.remove(atOffsets: offsets)
        }
    }
    var body: some View {
        ZStack {
            BackgroundView()
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .font(.title)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            Text("Rep Range: \(exercise.repRange.isEmpty ? "Not Set" : exercise.repRange)")
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                            Text(exercise.category)
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                        }
                        Spacer()
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                Section {
                    ZStack(alignment: .leading) {
                        TextEditor(text: $exercise.notes)
                            .focused($notesFocused)
                            .textEditorStyle(.plain)
                            .autocorrectionDisabled()
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
                .listRowBackground(Color.clear)
                Section {
                    if !exercise.sets.isEmpty {
                        HStack {
                            Text("Set")
                                .padding(.trailing)
                            Text("Minutes")
                                Spacer()
                            Text("Seconds")
                                Spacer()
                        }
                        .fontWeight(.semibold)
                        .font(.title2)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    ForEach(exercise.sets.indices, id: \.self) { setIndex in
                        HStack {
                            Text("\(setIndex + 1)")
                                .padding(.horizontal)
                                .padding(.vertical, 7)
                                .background(BlurView())
                                .cornerRadius(12)
                            TextField("", value: $exercise.sets[setIndex].restMinutes, format: .number)
                                .keyboardType(.numberPad)
                                .padding(.horizontal)
                                .padding(.vertical, 7)
                                .background(BlurView())
                                .cornerRadius(12)
                                .focused($keyboardActive)
                            TextField("", value: $exercise.sets[setIndex].restSeconds, format: .number)
                                .keyboardType(.numberPad)
                                .padding(.horizontal)
                                .padding(.vertical, 7)
                                .background(BlurView())
                                .cornerRadius(12)
                                .focused($keyboardActive)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .font(.title)
                    }
                    .onDelete(perform: deleteSet)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                Section {
                    Button(action: {
                        withAnimation {
                            if exercise.sets.isEmpty {
                                exercise.sets.append(TempSet(reps: 0, weight: 0, restMinutes: 0, restSeconds: 0, completed: false))
                            } else {
                                let lastSet = exercise.sets.last!
                                exercise.sets.append(TempSet(reps: lastSet.reps, weight: lastSet.weight, restMinutes: lastSet.restMinutes, restSeconds: lastSet.restSeconds, completed: false))
                            }
                        }
                    }, label: {
                        HStack {
                            Label("Add Set", systemImage: "plus")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundStyle(Color.primary)
                    })
                    .padding()
                    .background(BlurView())
                    .cornerRadius(12)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
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
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: {
                        setRepRangeSheet.toggle()
                    }, label: {
                        Label("Set Rep Range", systemImage: "alternatingcurrent")
                    })
                } label: {
                    Image(systemName: "chevron.down.circle")
                        .font(.title2)
                }
                .sheet(isPresented: $setRepRangeSheet) {
                    SetRepRangeView(exercise: $exercise)
                        .interactiveDismissDisabled()
                        .presentationDetents([.medium])
                }
            }
        }
    }
}
