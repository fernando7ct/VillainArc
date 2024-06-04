import SwiftUI

struct SetRestTimeView: View {
    @Binding var exercise: TempExercise
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                List {
                    HStack {
                        Text("Set")
                            .offset(x: 5)
                        Text("Minutes")
                            .offset(x: 40)
                        Text("Seconds")
                            .offset(x: 140)
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
                            TextField("", value: $exercise.sets[setIndex].restMinutes, format: .number)
                                .keyboardType(.numberPad)
                                .padding(.horizontal)
                                .padding(.vertical, 7)
                                .background(BlurView())
                                .cornerRadius(12)
                            TextField("", value: $exercise.sets[setIndex].restSeconds, format: .number)
                                .keyboardType(.numberPad)
                                .padding(.horizontal)
                                .padding(.vertical, 7)
                                .background(BlurView())
                                .cornerRadius(12)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .font(.title2)
                    }
                }
                .listStyle(.plain)
                .navigationTitle("Set Rest Times")
                .navigationBarTitleDisplayMode(.inline)
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
}
