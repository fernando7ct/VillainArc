import SwiftUI

struct EditEntryFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var food: NutritionFood
    var entry: NutritionEntry
    @State private var servingsCount: Double = 1
    @State private var totalServings: Double
    @State private var totalServings2: Double
    @State private var servingSizeSelected: Int = 1
    @State private var showingServingSize2 = false
    @State private var pickerDisplay = "Servings Count"
    
    init(food: NutritionFood, entry: NutritionEntry) {
        self.food = food
        self.entry = entry
        self._servingsCount = State(initialValue: food.servingsCount)
        self._totalServings = State(initialValue: food.servingsCount * food.servingSizeDigit)
        self._totalServings2 = State(initialValue: food.servingsCount * food.servingSizeDigit2)
    }
    
    private func saveFood() {
        DataManager.shared.editEntryFood(entry: entry, food: food, servingsCount: servingsCount, context: context)
        dismiss()
    }
    
    private func deleteFood() {
        DataManager.shared.deleteEntryFood(entry: entry, food: food, context: context)
        dismiss()
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .center, spacing: 0) {
                    HStack {
                        TextField("# of Servings", value: $servingsCount, format: .number)
                            .keyboardType(.decimalPad)
                            .onChange(of: servingsCount) {
                                totalServings = servingsCount * food.servingSizeDigit
                            }
                        Spacer()
                        Text("Number of Servings")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)
                    }
                    Text("-or-")
                        .foregroundStyle(Color.secondary)
                        .fontWeight(.semibold)
                    HStack {
                        if servingSizeSelected == 1 {
                            TextField("Total Servings", value: $totalServings, format: .number)
                                .keyboardType(.decimalPad)
                                .onChange(of: totalServings) {
                                    servingsCount = totalServings / food.servingSizeDigit
                                    totalServings2 = servingsCount * food.servingSizeDigit2
                                }
                        } else {
                            TextField("Total Servings", value: $totalServings2, format: .number)
                                .keyboardType(.decimalPad)
                                .onChange(of: totalServings2) {
                                    servingsCount = totalServings2 / food.servingSizeDigit2
                                    totalServings = servingsCount * food.servingSizeDigit
                                }
                        }
                        Spacer()
                        if servingSizeSelected == 1 {
                            Text(food.servingSizeUnit)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.secondary)
                                .onTapGesture {
                                    if !food.servingSizeUnit2.isEmpty {
                                        withAnimation {
                                            servingSizeSelected = 2
                                        }
                                    }
                                }
                        } else {
                            Text(food.servingSizeUnit2)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.secondary)
                                .onTapGesture {
                                    withAnimation {
                                        servingSizeSelected = 1
                                    }
                                }
                        }
                    }
                }
            }
            .listRowBackground(BlurView())
            .listRowSeparator(.hidden)
            Section {
                HStack {
                    Text(food.name)
                    Spacer()
                    Text("Name")
                        .foregroundStyle(Color.secondary)
                }
                .fontWeight(.semibold)
                HStack {
                    Text(food.brand)
                    Spacer()
                    Text("Brand")
                        .foregroundStyle(Color.secondary)
                }
                .fontWeight(.semibold)
                HStack {
                    if !showingServingSize2 {
                        Text("\(formattedDouble(food.servingSizeDigit)) \(food.servingSizeUnit)")
                            .onTapGesture {
                                if food.servingSizeDigit2 != 0 && food.servingSizeUnit2 != "" {
                                    withAnimation {
                                        showingServingSize2.toggle()
                                    }
                                }
                            }
                    } else {
                        Text("\(formattedDouble(food.servingSizeDigit2)) \(food.servingSizeUnit2)")
                            .onTapGesture {
                                withAnimation {
                                    showingServingSize2.toggle()
                                }
                            }
                    }
                    Spacer()
                    Text("Serving Size\(food.servingSizeDigit2 != 0 && food.servingSizeUnit2 != "" ? "(s)" : "")")
                        .foregroundStyle(Color.secondary)
                }
                .fontWeight(.semibold)
                HStack {
                    Text(formattedDouble(food.servingsPerContainer))
                    Spacer()
                    Text("Servings Per Container")
                        .foregroundStyle(Color.secondary)
                }
                .fontWeight(.semibold)
            }
            .listRowBackground(BlurView())
            .listRowSeparator(.hidden)
            Section {
                HStack {
                    Text(formattedDouble(pickerDisplay == "1 Serving" ? food.calories: food.calories * servingsCount))
                    Spacer()
                    Text("Calories")
                        .foregroundStyle(Color.secondary)
                }
                .fontWeight(.semibold)
                HStack {
                    Text(formattedDouble(pickerDisplay == "1 Serving" ? food.protein: food.protein * servingsCount))
                    Spacer()
                    Text("Protein (g)")
                        .foregroundStyle(Color.secondary)
                }
                .fontWeight(.semibold)
                HStack {
                    Text(formattedDouble(pickerDisplay == "1 Serving" ?  food.carbs : food.carbs * servingsCount))
                    Spacer()
                    Text("Carbs (g)")
                        .foregroundStyle(Color.secondary)
                }
                .fontWeight(.semibold)
                HStack {
                    Text(formattedDouble(pickerDisplay == "1 Serving" ? food.fat : food.fat * servingsCount))
                    Spacer()
                    Text("Fat (g)")
                        .foregroundStyle(Color.secondary)
                }
                .fontWeight(.semibold)
            } header: {
                Picker("", selection: $pickerDisplay) {
                    Text("1 Serving").tag("1 Serving")
                    Text("\(formattedDouble(servingsCount)) Servings").tag("Servings Count")
                }
                .pickerStyle(.segmented)
                .textCase(.none)
                .padding(.horizontal, -15)
            }
            .listRowBackground(BlurView())
            .listRowSeparator(.hidden)
            Section {
                Button {
                    deleteFood()
                } label: {
                    HStack {
                        Label("Delete Food", systemImage: "trash.fill")
                        Spacer()
                    }
                }
                .foregroundStyle(.red)
                .fontWeight(.semibold)
                .buttonStyle(BorderlessButtonStyle())
            }
            .listRowBackground(Color.red.opacity(0.2))
        }
        .scrollContentBackground(.hidden)
        .background(BackgroundView())
        .onTapGesture {
            hideKeyboard()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    saveFood()
                } label: {
                    Text("Save")
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
                .disabled(servingsCount == 0)
                .opacity(servingsCount == 0 ? 0.5 : 1)
            }
        }
    }
}
