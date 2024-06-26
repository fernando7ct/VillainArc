import SwiftUI

struct FoodToEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var food: NutritionFood
    var entry: NutritionEntry
    var category: String
    @State private var servingsCount: Double = 1
    @State private var totalServings: Double
    @FocusState private var servingsFocused: Bool
    @State private var pickerDisplay = "Servings Count"
    
    init(food: NutritionFood, entry: NutritionEntry, category: String) {
        self.food = food
        self.entry = entry
        self.category = category
        self._servingsCount = State(initialValue: food.servingsCount)
        self._totalServings = State(initialValue: food.servingsCount * food.servingSizeDigit)
    }
    
    private func saveFood() {
        DataManager.shared.addFoodToEntry(food: food, entry: entry, servingsCount: servingsCount, category: category, context: context)
        dismiss()
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
            Form {
                Section {
                    VStack(alignment: .center, spacing: 0) {
                        HStack {
                            TextField("# of Servings", value: $servingsCount, format: .number)
                                .keyboardType(.decimalPad)
                                .focused($servingsFocused)
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
                            TextField("Total Servings", value: $totalServings, format: .number)
                                .keyboardType(.decimalPad)
                                .onChange(of: totalServings) {
                                    servingsCount = totalServings / food.servingSizeDigit
                                }
                            Spacer()
                            Text(food.servingSizeUnit)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.secondary)
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
                        Text("\(formattedDouble(food.servingSizeDigit)) \(food.servingSizeUnit)")
                        Spacer()
                        Text("Serving Size")
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
            }
            .scrollContentBackground(.hidden)
            .onAppear {
                servingsFocused = true
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .navigationTitle(food.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    saveFood()
                }, label: {
                    Text("Save")
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                })
                .disabled(servingsCount == 0)
                .opacity(servingsCount == 0 ? 0.5 : 1)
            }
        }
    }
}
