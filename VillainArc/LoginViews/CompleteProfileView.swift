import SwiftUI

struct CompleteProfileView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("isSignedIn") var isSignedIn = false
    @State var userID: String
    @State var name: String
    @State var dateJoined: Date
    @State private var birthday: Date = Date()
    @State private var heightFeet: Int = 0
    @State private var heightInches: Int = 0
    @State private var sex: String = "Not selected"
    @State private var isSaving = false
    @State private var showingDatePicker = false
    
    private func gestureTap() {
        if showingDatePicker {
            showingDatePicker.toggle()
        }
    }
    
    var body: some View {
        if !isSaving {
            NavigationView {
                Form {
                    Section {
                        TextField("Name", text: $name)
                            .onTapGesture {
                                gestureTap()
                            }
                            .listRowBackground(BlurView())
                    }
                    Section {
                        HStack {
                            Text(birthday, format: .dateTime.month(.wide).day().year())
                                .foregroundColor(showingDatePicker ? .blue : .primary)
                                .onTapGesture {
                                    showingDatePicker.toggle()
                                }
                            Spacer()
                            Text("Birthday")
                                .foregroundColor(.gray)
                                .fontWeight(.semibold)
                        }
                        .listRowBackground(BlurView())
                    }
                    Section {
                        HStack {
                            TextField("Feet", value: $heightFeet, format: .number)
                                .keyboardType(.numberPad)
                                .onTapGesture {
                                    gestureTap()
                                }
                            Spacer()
                            Text("Height (ft)")
                                .foregroundColor(.gray)
                                .fontWeight(.semibold)
                        }
                        HStack {
                            TextField("Inches", value: $heightInches, format: .number)
                                .keyboardType(.numberPad)
                                .onTapGesture {
                                    gestureTap()
                                }
                            Spacer()
                            Text("Height (inches)")
                                .foregroundColor(.gray)
                                .fontWeight(.semibold)
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(BlurView())
                    Section {
                        Picker("Sex", selection: $sex) {
                            Text("Not selected").tag("Not selected")
                            Text("Male").tag("Male")
                            Text("Female").tag("Female")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .listRowBackground(BlurView())
                    }
                }
                .navigationTitle("Complete Profile")
                .scrollDisabled(true)
                .scrollContentBackground(.hidden)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            completeProfile()
                        } label: {
                            Text("Save")
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        }
                        .disabled(heightFeet == 0 || heightInches == 0 || name.isEmpty || sex == "Not selected")
                        .opacity(heightFeet == 0 || heightInches == 0 || name.isEmpty || sex == "Not selected" ? 0.5 : 1)
                    }
                }
                .overlay(alignment: .bottom) {
                    if showingDatePicker {
                        DatePicker("", selection: $birthday, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                    }
                }
                .background(BackgroundView())
                .onTapGesture {
                    hideKeyboard()
                }
            }
        } else {
            ProgressView("Loading...")
        }
    }
    
    private func completeProfile() {
        isSaving = true
        DataManager.shared.createUser(userID: userID, userName: name, dateJoined: dateJoined, birthday: birthday, heightFeet: heightFeet, heightInches: heightInches, sex: sex, context: context) { success in
            if success {
                isSaving = false
                isSignedIn = true
            }
        }
    }
}

#Preview {
    CompleteProfileView(userID: "", name: "", dateJoined: Date())
}
