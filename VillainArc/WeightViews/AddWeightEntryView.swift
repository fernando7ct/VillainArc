import SwiftUI

struct AddWeightEntryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isWeightFieldFocused: Bool
    @State private var weight = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var time = Date()
    @State private var showingDatePicker = false
    @State private var showingTimePicker = false
    @FocusState private var notesFocused: Bool

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }
    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }
    private func addWeightEntry() {
        let calendar = Calendar.current
        var combinedDateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        combinedDateComponents.hour = timeComponents.hour
        combinedDateComponents.minute = timeComponents.minute
        combinedDateComponents.second = timeComponents.second
        guard let combinedDate = calendar.date(from: combinedDateComponents) else {
            print("Failed to combine date and time components")
            return
        }
        DataManager.shared.saveWeightEntry(weight: Double(weight)!, notes: notes, date: combinedDate, context: context)
        dismiss()
    }
    private func gestureTap() {
        if showingTimePicker {
            showingTimePicker.toggle()
        }
        if showingDatePicker {
            showingDatePicker.toggle()
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                VStack {
                    Form {
                        Section {
                            HStack {
                                Text(dateFormatter.string(from: date))
                                    .foregroundColor(showingDatePicker ? .blue : .primary)
                                    .onTapGesture {
                                        showingDatePicker.toggle()
                                        if showingTimePicker {
                                            showingTimePicker.toggle()
                                        }
                                    }
                                Spacer()
                                Text("Date")
                                    .foregroundColor(.gray)
                                    .fontWeight(.semibold)
                            }
                            HStack {
                                Text(timeFormatter.string(from: time))
                                    .foregroundColor(showingTimePicker ? .blue : .primary)
                                    .onTapGesture {
                                        showingTimePicker.toggle()
                                        if showingDatePicker {
                                            showingDatePicker.toggle()
                                        }
                                    }
                                Spacer()
                                Text("Time")
                                    .foregroundColor(.gray)
                                    .fontWeight(.semibold)
                            }
                            HStack {
                                TextField("Enter Your Weight", text: $weight)
                                    .keyboardType(.decimalPad)
                                    .focused($isWeightFieldFocused)
                                    .onTapGesture {
                                        gestureTap()
                                    }
                                Spacer()
                                Text("Weight")
                                    .foregroundColor(.gray)
                                    .fontWeight(.semibold)
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(BlurView())
                        Section {
                            ZStack(alignment: .leading) {
                                TextEditor(text: $notes)
                                    .onTapGesture {
                                        gestureTap()
                                    }
                                    .textEditorStyle(.plain)
                                    .focused($notesFocused)
                                if !notesFocused && notes.isEmpty {
                                    Text("Notes...")
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                        .onTapGesture {
                                            notesFocused = true
                                            gestureTap()
                                        }
                                }
                            }
                        }
                        .listRowBackground(BlurView())
                    }
                    .scrollContentBackground(.hidden)
                    if showingDatePicker {
                        Spacer()
                        DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                    }
                    if showingTimePicker {
                        Spacer()
                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                    }
                }
            }
            .navigationTitle("Add Weight Entry")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        addWeightEntry()
                    }, label: {
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    })
                    .disabled(Double(weight) == 0 || weight.isEmpty || weight == ".")
                    .opacity(Double(weight) == 0 || weight.isEmpty || weight == "." ? 0.5 : 1)
                }
            }
        }
        .onAppear {
            isWeightFieldFocused = true
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
}

#Preview {
    AddWeightEntryView()
}
