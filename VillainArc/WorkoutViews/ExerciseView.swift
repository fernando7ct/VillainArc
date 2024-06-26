import SwiftUI

struct ExerciseView: View {
    @Binding var exercise: TempExercise
    @ObservedObject var timer: TimerDisplayViewModel
    var isEditing: Bool
    @FocusState private var keyboardActive: Bool
    @FocusState private var notesFocused: Bool
    @State private var showHistorySheet = false
    @State private var setRestTimeSheet = false
    @State private var setRepRangeSheet = false
    let updateLiveActivity: () -> Void
    
    private func deleteSet(at offsets: IndexSet) {
        withAnimation {
            exercise.sets.remove(atOffsets: offsets)
        }
        updateLiveActivity()
    }
    private func populateSets(from historySets: [TempSet]) {
        exercise.sets = historySets
        updateLiveActivity()
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
                        TimerDisplayView(viewModel: timer)
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
                            Text("Reps")
                            Spacer()
                            Text("Weight")
                            Spacer()
                        }
                        .fontWeight(.semibold)
                        .font(.title2)
                    }
                    ForEach(exercise.sets.indices, id: \.self) { setIndex in
                        HStack {
                            Text("\(setIndex + 1)")
                                .padding(.horizontal)
                                .padding(.vertical, 7)
                                .background(BlurView())
                                .cornerRadius(12)
                            TextField("", value: $exercise.sets[setIndex].reps, format: .number)
                                .keyboardType(.numberPad)
                                .padding(.horizontal)
                                .padding(.vertical, 7)
                                .background(BlurView())
                                .cornerRadius(12)
                                .focused($keyboardActive)
                                .onChange(of: exercise.sets[setIndex].reps) {
                                    updateLiveActivity()
                                }
                            TextField("", value: $exercise.sets[setIndex].weight, format: .number)
                                .keyboardType(.decimalPad)
                                .padding(.horizontal)
                                .padding(.vertical, 7)
                                .background(BlurView())
                                .cornerRadius(12)
                                .focused($keyboardActive)
                                .onChange(of: exercise.sets[setIndex].weight) {
                                    updateLiveActivity()
                                }
                            if !isEditing {
                                Button(action: {
                                    if !exercise.sets[setIndex].completed {
                                        timer.startRestTimer(minutes: exercise.sets[setIndex].restMinutes, seconds: exercise.sets[setIndex].restSeconds)
                                    }
                                    exercise.sets[setIndex].completed.toggle()
                                    updateLiveActivity()
                                }, label: {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(exercise.sets[setIndex].completed ? .green : .gray)
                                        .fontWeight(.semibold)
                                })
                                .padding(.horizontal, 8)
                                .padding(.vertical, 9)
                                .background(BlurView())
                                .cornerRadius(12)
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
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
                            updateLiveActivity()
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
            ToolbarItem(placement: .topBarTrailing, content: {
                Menu {
                    if !exercise.sets.isEmpty {
                        Button(action: {
                            setRestTimeSheet.toggle()
                        }, label: {
                            Label("Rest Times", systemImage: "timer")
                        })
                    }
                    Button(action: {
                        setRepRangeSheet.toggle()
                    }, label: {
                        Label("Rep Range", systemImage: "alternatingcurrent")
                    })
                    Button(action: {
                        showHistorySheet.toggle()
                    }, label: {
                        Label("History", systemImage: "clock")
                    })
                } label: {
                    Image(systemName: "chevron.down.circle")
                        .font(.title2)
                }
                .sheet(isPresented: $showHistorySheet) {
                    ExerciseHistoryView(exerciseName: $exercise.name, onSelectHistory: populateSets)
                        .presentationDragIndicator(.visible)
                        .presentationDetents([.medium, .large])
                }
                .sheet(isPresented: $setRestTimeSheet) {
                    SetRestTimeView(exercise: $exercise)
                        .presentationDragIndicator(.visible)
                        .presentationDetents([.medium, .large])
                }
                .sheet(isPresented: $setRepRangeSheet) {
                    SetRepRangeView(exercise: $exercise)
                        .interactiveDismissDisabled()
                        .presentationDetents([.medium])
                }
            })
        }
    }
}
