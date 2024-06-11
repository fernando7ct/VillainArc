import SwiftUI

struct ExerciseView: View {
    @Binding var exercise: TempExercise
    @ObservedObject var timer: TimerDisplayViewModel
    @FocusState private var keyboardActive: Bool
    @FocusState private var notesFocused: Bool
    @State private var showHistorySheet = false
    @State private var setRestTimeSheet = false
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
                    TimerDisplayView(viewModel: timer)
                }
                .padding(.horizontal)
                List {
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
                                    .background(BlurView())
                                    .cornerRadius(12)
                                TextField("", value: $exercise.sets[setIndex].reps, format: .number)
                                    .keyboardType(.numberPad)
                                    .padding(.horizontal)
                                    .padding(.vertical, 7)
                                    .background(BlurView())
                                    .cornerRadius(12)
                                    .focused($keyboardActive)
                                TextField("", value: $exercise.sets[setIndex].weight, format: .number)
                                    .keyboardType(.decimalPad)
                                    .padding(.horizontal)
                                    .padding(.vertical, 7)
                                    .background(BlurView())
                                    .cornerRadius(12)
                                    .focused($keyboardActive)
                                Button(action: {
                                    if !exercise.sets[setIndex].completed {
                                        timer.startRestTimer(minutes: exercise.sets[setIndex].restMinutes, seconds: exercise.sets[setIndex].restSeconds)
                                    }
                                    exercise.sets[setIndex].completed.toggle()
                                    updateLiveActivity()
                                }, label: {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(exercise.sets[setIndex].completed ? .green : .gray)
                                        .font(.title)
                                        .fontWeight(.semibold)
                                })
                                .padding(.horizontal, 7)
                                .padding(.vertical, 7)
                                .background(BlurView())
                                .cornerRadius(12)
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .font(.title2)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing, content: {
                Menu {
                    if !exercise.sets.isEmpty {
                        Button(action: {
                            setRestTimeSheet.toggle()
                        }, label: {
                            Label("Set Rest Times", systemImage: "timer")
                        })
                    }
                    Button(action: {
                        showHistorySheet.toggle()
                    }, label: {
                        Label("Exercise History", systemImage: "clock")
                    })
                } label: {
                    Image(systemName: "chevron.down.circle")
                        .font(.title2)
                }
                .sheet(isPresented: $showHistorySheet) {
                    ExerciseHistoryView(exerciseName: $exercise.name, onSelectHistory: populateSets)
                        .presentationDragIndicator(.visible)
                }
                .sheet(isPresented: $setRestTimeSheet) {
                    SetRestTimeView(exercise: $exercise)
                        .presentationDragIndicator(.visible)
                }
            })
        }
    }
}
