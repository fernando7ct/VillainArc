import SwiftUI

struct AddWeightEntryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isWeightFieldFocused: Bool
    @State private var weight = ""
    @State private var date = Date()
    @State private var time = Date()
    @State private var showingDatePicker = false
    @State private var showingTimePicker = false

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
        let combinedDate = calendar.date(from: combinedDateComponents)
        guard let combinedDate = calendar.date(from: combinedDateComponents) else {
            print("Failed to combine date and time components")
            return
        }
        DataManager.shared.saveWeightEntry(weight: Double(weight)!, date: combinedDate, context: context)
        dismiss()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
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
                    .listRowSeparator(.hidden)
                    HStack {
                        TextField("Enter Your Weight", text: $weight)
                            .keyboardType(.decimalPad)
                            .focused($isWeightFieldFocused)
                            .onTapGesture {
                                if showingTimePicker {
                                    showingTimePicker.toggle()
                                }
                                if showingDatePicker {
                                    showingDatePicker.toggle()
                                }
                            }
                        Spacer()
                        Text("Weight")
                            .foregroundColor(.gray)
                            .fontWeight(.semibold)
                    }
                    .listRowSeparator(.hidden)
                }
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
                    Button {
                        addWeightEntry()
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
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
