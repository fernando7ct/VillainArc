import SwiftUI
import PhotosUI

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
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var uploadingImage = false
    
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
        let newWeightEntry = WeightEntry(id: UUID().uuidString, weight: Double(weight)!, notes: notes, date: combinedDate, photoData: selectedPhotoData)
        DataManager.shared.saveWeightEntry(weightEntry: newWeightEntry, context: context, saveToHealthKit: true)
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
    private func removePhotoData() {
        selectedPhoto = nil
        selectedPhotoData = nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text(date, format: .dateTime.month(.wide).day().year())
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
                        Text(time, format: .dateTime.hour().minute())
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
                    TextField("Notes", text: $notes, axis: .vertical)
                        .autocorrectionDisabled()
                        .onTapGesture {
                            gestureTap()
                        }
                }
                .listRowBackground(BlurView())
                Section {
                    if uploadingImage {
                        Text("Uploading..")
                            .foregroundStyle(Color.secondary)
                    } else {
                        if selectedPhotoData != nil {
                            HStack {
                                Text("Image uploaded")
                                    .foregroundStyle(.blue)
                                Spacer()
                                Button {
                                    removePhotoData()
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .onTapGesture {
                                gestureTap()
                            }
                        } else {
                            PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                                HStack {
                                    Label("Add Image", systemImage: "photo")
                                    Spacer()
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .onTapGesture {
                                gestureTap()
                            }
                        }
                    }
                }
                .listRowBackground(BlurView())
            }
            .scrollContentBackground(.hidden)
            .background(BackgroundView())
            .overlay(alignment: .bottom) {
                if showingDatePicker {
                    DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }
                if showingTimePicker {
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
                        Text("Save")
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                    .disabled(Double(weight) == 0 || weight.isEmpty || weight == "." || uploadingImage)
                    .opacity(Double(weight) == 0 || weight.isEmpty || weight == "." || uploadingImage ? 0.5 : 1)
                }
            }
            .task(id: selectedPhoto) {
                uploadingImage = true
                if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                    selectedPhotoData = data
                }
                uploadingImage = false
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
    NavigationView {
        AddWeightEntryView()
            .tint(.primary)
    }
}
