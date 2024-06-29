import SwiftUI

enum ServingSizeUnits: String, CaseIterable, Identifiable {
    case g = "grams"
    case oz = "oz"
    case cup = "cup"
    case scoop = "scoop"
    case piece = "piece"
    case tbsp = "tbsp"
    case slice = "slice"
    case mg = "mg"
    case IU = "IU"
    case can = "can"
    case packet = "packet"
    case bar = "bar"
    case bottle = "bottle"
    case pill = "pill"
    case flOz = "fl oz"
    case egg = "egg"
    
    var id: String { self.rawValue }
}

struct CreateFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var barcode: String
    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var servingSizeDigit: Double = 0
    @State private var servingSizeUnit: ServingSizeUnits = .g
    @State private var protein: Double = 0
    @State private var carbs: Double = 0
    @State private var fat: Double = 0
    @State private var calories: Double = 0
    @State private var servingSize = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private func validateServingSize() -> Bool {
        let components = servingSize.split(separator: " ")
        guard components.count == 2,
              let digit = Double(components[0]),
              let unit = ServingSizeUnits(rawValue: String(components[1])) else {
            return false
        }
        servingSizeDigit = digit
        servingSizeUnit = unit
        return true
    }

    private func createFood() {
        if validateServingSize() {
            let newFood = NutritionFood(
                id: UUID().uuidString,
                name: name,
                brand: brand,
                barcode: barcode,
                servingSizeDigit: servingSizeDigit,
                servingSizeUnit: servingSizeUnit.rawValue,
                servingsCount: 1,
                date: Date(),
                mealCategory: "",
                protein: protein,
                carbs: carbs,
                fat: fat,
                calories: calories,
                entry: nil
            )
            DataManager.shared.createNutritionFood(food: newFood, context: context)
            dismiss()
        } else {
            alertMessage = "Please enter a valid serving size (e.g., '1 cup')."
            showAlert = true
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                Form {
                    Section {
                        HStack {
                            TextField("Name", text: $name)
                            Spacer()
                            Text("Name")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.secondary)
                        }
                        HStack {
                            TextField("Brand", text: $brand)
                            Spacer()
                            Text("Brand")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    .listRowBackground(BlurView())
                    .listRowSeparator(.hidden)
                    Section {
                        HStack {
                            TextField("Ex: 1 Cup", text: $servingSize)
                            Spacer()
                            Text("Serving Size")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    .listRowBackground(BlurView())
                    .listRowSeparator(.hidden)
                    Section {
                        HStack {
                            TextField("Calories", value: $calories, format: .number)
                                .keyboardType(.numberPad)
                            Spacer()
                            Text("Calories")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.secondary)
                        }
                        HStack {
                            TextField("Protein", value: $protein, format: .number)
                                .keyboardType(.decimalPad)
                            Spacer()
                            Text("Protein (g)")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.secondary)
                        }
                        HStack {
                            TextField("Carbs", value: $carbs, format: .number)
                                .keyboardType(.decimalPad)
                            Spacer()
                            Text("Carbs (g)")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.secondary)
                        }
                        HStack {
                            TextField("Fat", value: $fat, format: .number)
                                .keyboardType(.decimalPad)
                            Spacer()
                            Text("Fat (g)")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    .listRowBackground(BlurView())
                    .listRowSeparator(.hidden)
                }
                .scrollContentBackground(.hidden)
            }
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle("New Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .foregroundStyle(.red)
                            .fontWeight(.semibold)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        createFood()
                    } label: {
                        Text("Create")
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                    }
                    .disabled(name.isEmpty || calories == 0 && protein == 0 && carbs == 0 && fat == 0)
                    .opacity(name.isEmpty || calories == 0 && protein == 0 && carbs == 0 && fat == 0 ? 0.5 : 1)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Invalid Serving Size"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}
