import SwiftUI

struct RestTimeField: View {
    @Binding var minutes: Int
    @Binding var seconds: Int
    @State private var inputText: String = "00:00"
    
    private func updateText() {
        let minutesString = String(format: "%02d", minutes)
        let secondsString = String(format: "%02d", seconds)
        inputText = "\(minutesString):\(secondsString)"
    }
    
    private func updateRestTime() {
        let components = inputText.split(separator: ":")
        if components.count == 2 {
            if let newMinutes = Int(components[0]), let newSeconds = Int(components[1]) {
                minutes = newMinutes
                seconds = newSeconds
            }
        }
    }
    
    var body: some View {
        TextField("00:00", text: $inputText)
            .keyboardType(.numberPad)
            .onChange(of: inputText) {
                let cleanedString = inputText.replacingOccurrences(of: ":", with: "")
                if let totalSeconds = Int(cleanedString) {
                    minutes = totalSeconds / 100
                    seconds = totalSeconds % 100
                    updateText()
                } else {
                    updateText()
                }
            }
            .onAppear {
                updateText()
            }
            .padding(.horizontal)
            .padding(.vertical, 7)
            .background(BlurView())
            .cornerRadius(12)
            .font(.title2)
    }
}

struct SetRestTimeView: View {
    @Binding var exercise: TempExercise
    @State private var sameRestMinutes = 0
    @State private var sameRestSeconds = 0
    @Environment(\.dismiss) private var dismiss
    
    private func updateAllRestTimes() {
        for setIndex in exercise.sets.indices {
            exercise.sets[setIndex].restMinutes = sameRestMinutes
            exercise.sets[setIndex].restSeconds = sameRestSeconds
        }
    }
    private func updateGlobalRestTime(setIndex: Int) {
        sameRestMinutes = exercise.sets[setIndex].restMinutes
        sameRestSeconds = exercise.sets[setIndex].restSeconds
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                List {
                    Section {
                        Toggle("Same Rest Times", isOn: $exercise.sameRestTimes)
                            .listRowBackground(BlurView())
                    }
                    .listRowSeparator(.hidden)
                    if !exercise.sameRestTimes {
                        HStack {
                            Text("Set")
                            Spacer()
                            Text("Rest Time")
                        }
                        .fontWeight(.semibold)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        ForEach(exercise.sets.indices, id: \.self) { setIndex in
                            HStack {
                                Text("\(setIndex + 1)")
                                    .padding(.horizontal)
                                    .padding(.vertical, 7)
                                    .background(BlurView())
                                    .cornerRadius(12)
                                Spacer()
                                RestTimeField(minutes: $exercise.sets[setIndex].restMinutes, seconds: $exercise.sets[setIndex].restSeconds)
                                    .frame(width: 100)
                                    .onChange(of: exercise.sets[setIndex].restMinutes) {
                                        updateGlobalRestTime(setIndex: setIndex)
                                    }
                                    .onChange(of: exercise.sets[setIndex].restSeconds) {
                                        updateGlobalRestTime(setIndex: setIndex)
                                    }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .font(.title2)
                        }
                    } else {
                        Section {
                            HStack {
                                Text("Rest Time")
                                    .fontWeight(.semibold)
                                Spacer()
                                RestTimeField(minutes: $sameRestMinutes, seconds: $sameRestSeconds)
                                    .onChange(of: sameRestMinutes) {
                                        updateAllRestTimes()
                                    }
                                    .onChange(of: sameRestSeconds) {
                                        updateAllRestTimes()
                                    }
                                    .frame(width: 100)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .listStyle(.plain)
                .navigationTitle("Set Rest Times")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    if let firstSet = exercise.sets.first {
                        sameRestMinutes = firstSet.restMinutes
                        sameRestSeconds = firstSet.restSeconds
                    }
                }
                .onDisappear {
                    if exercise.sameRestTimes {
                        updateAllRestTimes()
                    }
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .fontWeight(.semibold)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
