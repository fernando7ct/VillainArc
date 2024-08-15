import SwiftUI

struct SetRepRangeView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var exercise: TempExercise
    @State private var rangeStart: Int = 0
    @State private var rangeEnd: Int = 0
    @State private var originalRange: String = ""
    @State private var failure: Bool = false
    
    func setProperties() {
        originalRange = exercise.repRange
        if !exercise.repRange.isEmpty {
            if exercise.repRange == "Until Failure" {
                failure = true
            } else {
                let parts = exercise.repRange.split(separator: "-")
                if parts.count == 2 {
                    rangeStart = Int(String(parts[0]))!
                    rangeEnd = Int(String(parts[1]))!
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                Toggle("Until Failure", isOn: $failure)
                    .padding(.horizontal)
                    .padding(.vertical, 7)
                    .background(BlurView())
                    .cornerRadius(12)
                    .font(.title2)
                
                if !failure {
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
                }
            }
            .vSpacing(.top)
            .padding(.horizontal)
            .background(BackgroundView())
            .onAppear {
                setProperties()
            }
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle("Rep Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        exercise.repRange = originalRange
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .foregroundStyle(.red)
                            .fontWeight(.semibold)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if failure {
                            exercise.repRange = "Until Failure"
                        } else {
                            if rangeStart == 0 && rangeEnd == 0 {
                                exercise.repRange = ""
                            } else {
                                exercise.repRange = "\(rangeStart)-\(rangeEnd)"
                            }
                        }
                        HapticManager.instance.impact(style: .light)
                        dismiss()
                    } label: {
                        Text("Save")
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

#Preview {
    SetRepRangeView(exercise: .constant(TempExercise(name: "", category: "", repRange: "", notes: "", sameRestTimes: false, sets: [])))
}
