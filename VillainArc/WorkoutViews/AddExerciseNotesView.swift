import SwiftUI

struct AddExerciseNotesView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var exercise: TempExercise
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                Form {
                    Section(content: {
                        TextEditor(text: $exercise.notes)
                            .listRowBackground(BlurView())
                            .autocorrectionDisabled()
                    }, header: {
                        Text("Notes")
                            .foregroundStyle(Color.primary)
                            .fontWeight(.semibold)
                    })
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        exercise.notes = ""
                    }, label: {
                        Text("Clear")
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                    })
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    })
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
}
