import SwiftUI

enum ServingSizeUnits: String, CaseIterable, Identifiable {
    case bag = "bag"
    case bagel = "bagel"
    case bar = "bar"
    case bottle = "bottle"
    case box = "box"
    case brownies = "brownies"
    case brownie = "brownie"
    case bun = "bun"
    case cakeCup = "cake cup"
    case can = "can"
    case capsule = "capsule"
    case chip = "chip"
    case chips = "chips"
    case cone = "cone"
    case cones = "cones"
    case container = "container"
    case cookie = "cookie"
    case cookies = "cookies"
    case cup = "cup"
    case egg = "egg"
    case empty = ""
    case flOz = "fl oz"
    case g = "g"
    case gummy = "gummy"
    case IU = "IU"
    case kg = "kg"
    case lb = "lb"
    case liter = "liter"
    case mL = "mL"
    case mcg = "mcg"
    case mg = "mg"
    case mint = "mint"
    case mints = "mints"
    case oz = "oz"
    case packet = "packet"
    case piece = "piece"
    case pieces = "pieces"
    case pill = "pill"
    case pouch = "pouch"
    case rope = "rope"
    case ropes = "ropes"
    case scoop = "scoop"
    case serving = "serving"
    case slice = "slice"
    case slices = "slices"
    case softgel = "softgel"
    case softgels = "softgels"
    case stick = "stick"
    case tablet = "tablet"
    case tbsp = "tbsp"
    case tsp = "tsp"
    case waffleCone = "waffle cone"
    
    var id: String { self.rawValue }
}

struct CreateFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var barcode: String
    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var servingSizeDigit: Double = 0
    @State private var servingSizeUnit: ServingSizeUnits = .empty
    @State private var servingSizeDigit2: Double = 0
    @State private var servingSizeUnit2: ServingSizeUnits = .empty
    @State private var servingsPerContainer: Double = 0
    @State private var protein: Double = 0
    @State private var carbs: Double = 0
    @State private var fat: Double = 0
    @State private var calories: Double = 0
    @State private var servingSize = ""
    @State private var servingSize2 = ""
    @State private var showAlert = false
    
    private func validateServingSize() -> Bool {
        let components = servingSize.split(separator: " ")
        if components.count == 3 {
            guard let digit = Double(components[0]), let unit = ServingSizeUnits(rawValue: String(components[1] + " " + components[2])) else {
                return false
            }
            servingSizeDigit = digit
            servingSizeUnit = unit
        } else if components.count == 2 {
            guard let digit = Double(components[0]),
                  let unit = ServingSizeUnits(rawValue: String(components[1])) else {
                return false
            }
            servingSizeDigit = digit
            servingSizeUnit = unit
        } else {
            return false
        }
        let components2 = servingSize2.split(separator: " ")
        if components2.count == 3 {
            guard let digit2 = Double(components2[0]),
                  let unit2 = ServingSizeUnits(rawValue: String(components2[1]) + " " + components2[2]) else {
                return false
            }
            servingSizeDigit2 = digit2
            servingSizeUnit2 = unit2
            return true
        } else if components2.count == 2 {
            guard let digit2 = Double(components2[0]),
                  let unit2 = ServingSizeUnits(rawValue: String(components2[1])) else {
                return false
            }
            servingSizeDigit2 = digit2
            servingSizeUnit2 = unit2
            return true
        } else if components2.count == 0 {
            let digit2 = 0.0
            let unit2 = ServingSizeUnits.empty
            servingSizeDigit2 = digit2
            servingSizeUnit2 = unit2
            return true
        } else {
            return false
        }
    }
    
    private func createFood() {
        if validateServingSize() {
            let newFood = NutritionFood(id: UUID().uuidString, name: name, brand: brand, barcode: barcode, servingSizeDigit: servingSizeDigit, servingSizeUnit: servingSizeUnit.rawValue, servingSizeDigit2: servingSizeDigit2, servingSizeUnit2: servingSizeUnit2.rawValue, servingsCount: 1, servingsPerContainer: servingsPerContainer, date: Date(), mealCategory: "", protein: protein, carbs: carbs, fat: fat, calories: calories, entry: nil)
            DataManager.shared.createNutritionFood(food: newFood, context: context)
            dismiss()
        } else {
            showAlert = true
        }
    }
    
    var body: some View {
        NavigationView {
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
                        TextField("Ex: 1 cup", text: $servingSize)
                        Spacer()
                        Text("Serving Size")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)
                    }
                    HStack {
                        TextField("Ex: 46 g", text: $servingSize2)
                        Spacer()
                        Text("Serving Size 2")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)
                    }
                    HStack {
                        TextField("Servings Per Container", value: $servingsPerContainer, format: .number)
                            .keyboardType(.decimalPad)
                        Spacer()
                        Text("Servings Per Container")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                } footer: {
                    Text("Valid Serving Size Units: bag, bagel, bar, bottle, box, brownie(s), bun, cake cup, can, capsule, chip(s), cone(s), container, cookie(s), cup, egg, fl oz, g, gummy, IU, kg, lb, liter, mL, mcg, mg, mint(s), oz, packet, piece(s), pill, pouch, rope(s), scoop, serving, slice(s), softgel(s), stick, tablet, tbsp, tsp, waffle cone")
                }
                .listRowBackground(BlurView())
                .listRowSeparator(.hidden)
                Section {
                    HStack {
                        TextField("Calories", value: $calories, format: .number)
                            .keyboardType(.decimalPad)
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
            .background(BackgroundView())
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle("New Food")
            .navigationBarTitleDisplayMode(.inline)
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
                    .disabled(name.isEmpty || servingSize.isEmpty)
                    .opacity(name.isEmpty || servingSize.isEmpty ? 0.5 : 1)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Invalid Serving Size(s)"), message: Text("Please enter a valid serving size (e.g., '1 cup')."), dismissButton: .default(Text("OK")))
            }
        }
    }
}

#Preview {
    CreateFoodView(barcode: "")
}
