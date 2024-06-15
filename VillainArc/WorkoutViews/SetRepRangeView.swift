import SwiftUI

struct SetRepRangeView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var exercise: TempExercise
    @State private var rangeStart: Int = 0
    @State private var rangeEnd: Int = 0
    @State private var originalRange: String = ""

    func setProperties() {
        originalRange = exercise.repRange
        if !exercise.repRange.isEmpty {
            let parts = exercise.repRange.split(separator: "-")
            if parts.count == 2 {
                rangeStart = Int(String(parts[0]))!
                rangeEnd = Int(String(parts[1]))!
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                VStack {
                    HStack {
                        TextField("", value: $rangeStart, format: .number)
                            .keyboardType(.numberPad)
                            .padding(.horizontal)
                            .padding(.vertical, 7)
                            .background(BlurView())
                            .cornerRadius(12)
                            .font(.title2)
                        Text("-")
                            .font(.title)
                        TextField("", value: $rangeEnd, format: .number)
                            .keyboardType(.numberPad)
                            .padding(.horizontal)
                            .padding(.vertical, 7)
                            .background(BlurView())
                            .cornerRadius(12)
                            .font(.title2)
                    }
                    .padding()
                    Spacer()
                }
            }
            .onAppear {
                setProperties()
            }
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle("Rep Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        exercise.repRange = originalRange
                        dismiss()
                    }, label: {
                        Text("Cancel")
                            .foregroundStyle(.red)
                            .fontWeight(.semibold)
                    })
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action:  {
                        if rangeStart == 0 && rangeEnd == 0 {
                            exercise.repRange = ""
                        } else {
                            exercise.repRange = "\(rangeStart)-\(rangeEnd)"
                        }
                        dismiss()
                    }, label: {
                        Text("Save")
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                    })
                }
            }
        }
    }
}
