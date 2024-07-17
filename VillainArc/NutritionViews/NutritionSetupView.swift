import SwiftUI
import SwiftData

struct NutritionSetupView: View {
    @AppStorage("nutritionSetup") var nutritionSetup = false
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var currentWeight: Double = 0
    @State private var goal: Double = 0
    @State private var activityLevel: Double = 1.375
    @State private var protein: Int = 0
    @State private var proteinPercentage: Double = 0.30
    @State private var carbs: Int = 0
    @State private var carbsPercentage: Double = 0.45
    @State private var fat: Int = 0
    @State private var fatPercentage: Double = 0.25
    @State private var calories: Int = 0
    @State private var age: Int = 0
    @State private var heightFeet: Int = 0
    @State private var heightInches: Int = 0
    @State private var sex: String = ""
    @State private var mealCategories: [String] = ["Breakfast", "Lunch", "Dinner", "Snacks", "", ""]
    @State var nutritionEntry: NutritionEntry?
    
    private func getUserData() {
        let userDescriptor = FetchDescriptor<User>()
        let weightDescriptor = FetchDescriptor<WeightEntry>(sortBy: [SortDescriptor(\WeightEntry.date, order: .reverse)])
        do {
            let user = try context.fetch(userDescriptor).first!
            if let weightEntry = try context.fetch(weightDescriptor).first {
                currentWeight = weightEntry.weight
            }
            heightFeet = user.heightFeet
            heightInches = user.heightInches
            sex = user.sex
            age = {
                let calendar = Calendar.current
                let currentDate = Date()
                let ageComponents = calendar.dateComponents([.year], from: user.birthday, to: currentDate)
                return ageComponents.year!
            }()
            updateData()
        } catch {
            print("Error getting user data \(error.localizedDescription)")
        }
    }
    private func getOldHubData() {
        let descriptor = FetchDescriptor<NutritionHub>()
        let hubs = try? context.fetch(descriptor)
        if let hub = hubs?.first {
            goal = hub.goal
            protein = Int(hub.proteinGoal)
            proteinPercentage = hub.proteinPercentage
            carbs = Int(hub.carbsGoal)
            carbsPercentage = hub.carbsPercentage
            fat = Int(hub.fatGoal)
            fatPercentage = hub.fatPercentage
            calories = Int(hub.caloriesGoal)
            activityLevel = hub.activityLevel
            updateData()
        }
    }
    private func updateData() {
        if currentWeight == 0 {
            protein = 0
            carbs = 0
            fat = 0
            calories = 0
        } else {
            let height = (Double(heightFeet) * 30.48) + (Double(heightInches) * 2.54)
            let weight = currentWeight * 0.45359237
            var BMR: Double
            if sex == "Male" {
                BMR = (10 * weight) + (6.25 * height) - Double(5 * age) + 5
            } else {
                BMR = (10 * weight) + (6.25 * height) - Double (5 * age) - 161
            }
            let TDEE = activityLevel * BMR
            calories = Int((goal * 500) + TDEE)
            let proteinCalories = Double(calories) * proteinPercentage
            let carbsCalories = Double(calories) * carbsPercentage
            let fatCalories = Double(calories) * fatPercentage
            protein = Int(proteinCalories / 4.0)
            carbs = Int(carbsCalories / 4.0)
            fat = Int(fatCalories / 9.0)
        }
    }
    private func hundredPercent() -> Bool {
        return (proteinPercentage + carbsPercentage + fatPercentage == 1.0)
    }
    private func createNutritionHub() {
        if let nutritionEntry {
            DataManager.shared.updateNutritionHub(goal: goal, proteinGoal: Double(protein), carbsGoal: Double(carbs), fatGoal: Double(fat), caloriesGoal: Double(calories), proteinPercentage: proteinPercentage, carbsPercentage: carbsPercentage, fatPercentage: fatPercentage, activityLevel: activityLevel, context: context, entry: nutritionEntry)
            dismiss()
        } else {
            DataManager.shared.createNutritionHub(goal: goal, proteinGoal: Double(protein), carbsGoal: Double(carbs), fatGoal: Double(fat), caloriesGoal: Double(calories), proteinPercentage: proteinPercentage, carbsPercentage: carbsPercentage, fatPercentage: fatPercentage, activityLevel: activityLevel, mealCategories: mealCategories, context: context)
            nutritionSetup = true
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                Form {
                    Section {
                        HStack {
                            Text("Weight")
                                .foregroundStyle(Color.secondary)
                                .fontWeight(.semibold)
                            Spacer()
                            TextField("Current Weight", value: $currentWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .onChange(of: currentWeight) {
                                    updateData()
                                }
                                .frame(width: 50)
                        }
                        .listRowBackground(BlurView())
                    }
                    Section {
                        Picker("Goal", selection: $goal) {
                            Text("Lose 2 lbs per week").tag(-2.0)
                            Text("Lose 1.5 lbs per week").tag(-1.5)
                            Text("Lose 1 lb per week").tag(-1.0)
                            Text("Lose 0.5 lbs per week").tag(-0.5)
                            Text("Maintain Weight").tag(0.0)
                            Text("Gain 0.5 lbs per week").tag(0.5)
                            Text("Gain 1 lb per week").tag(1.0)
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.secondary)
                        .pickerStyle(.menu)
                        .onChange(of: goal) {
                            updateData()
                        }
                        
                    }
                    .listRowBackground(BlurView())
                    Section {
                        Picker("Activity Level", selection: $activityLevel) {
                            Text("Little or no exercise").tag(1.2)
                            Text("Lightly Active").tag(1.375)
                            Text("Moderately Active").tag(1.55)
                            Text("Active").tag(1.725)
                            Text("Very Active").tag(1.9)
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.secondary)
                        .pickerStyle(.menu)
                        .onChange(of: activityLevel) {
                            updateData()
                        }
                    }
                    .listRowBackground(BlurView())
                    Section {
                        HStack {
                            Text("Calories")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.secondary)
                            Spacer()
                            Text("\(calories)")
                        }
                    }
                    .listRowBackground(BlurView())
                    Section {
                        HStack {
                            HStack(alignment: .bottom, spacing: 5) {
                                Text("Protein")
                                Text("\(protein) g")
                                    .font(.caption)
                                    .offset(y: -1)
                            }
                            .foregroundStyle(Color.secondary)
                            .fontWeight(.semibold)
                            Spacer()
                            Picker("Protein", selection: $proteinPercentage) {
                                ForEach(0...20, id: \.self) { index in
                                    let value = index * 5
                                    Text("\(value)%").tag(Double(value) * 0.01)
                                        .foregroundStyle(hundredPercent() ? Color.green : Color.red)
                                }
                            }
                            .frame(width: 100, height: 45)
                            .pickerStyle(.wheel)
                            .onChange(of: proteinPercentage) {
                                updateData()
                            }
                        }
                        HStack {
                            HStack(alignment: .bottom, spacing: 5) {
                                Text("Carbs")
                                Text("\(carbs) g")
                                    .font(.caption)
                                    .offset(y: -1)
                            }
                            .foregroundStyle(Color.secondary)
                            .fontWeight(.semibold)
                            Spacer()
                            Picker("Carbs", selection: $carbsPercentage) {
                                ForEach(0...20, id: \.self) { index in
                                    let value = index * 5
                                    Text("\(value)%").tag(Double(value) * 0.01)
                                        .foregroundStyle(hundredPercent() ? Color.green : Color.red)
                                }
                            }
                            .frame(width: 100, height: 45)
                            .pickerStyle(.wheel)
                            .onChange(of: carbsPercentage) {
                                updateData()
                            }
                        }
                        HStack {
                            HStack(alignment: .bottom, spacing: 5) {
                                Text("Fat")
                                Text("\(fat) g")
                                    .font(.caption)
                                    .offset(y: -1)
                            }
                            .foregroundStyle(Color.secondary)
                            .fontWeight(.semibold)
                            Spacer()
                            Picker("Fat", selection: $fatPercentage) {
                                ForEach(0...20, id: \.self) { index in
                                    let value = index * 5
                                    Text("\(value)%").tag(Double(value) * 0.01)
                                        .foregroundStyle(hundredPercent() ? Color.green : Color.red)
                                }
                            }
                            .frame(width: 100, height: 45)
                            .pickerStyle(.wheel)
                            .onChange(of: fatPercentage) {
                                updateData()
                            }
                        }
                    } header: {
                        HStack {
                            Spacer()
                            HStack(spacing: 3) {
                                Text("Total:")
                                Text("\(Int((proteinPercentage + carbsPercentage + fatPercentage) * 100))%")
                                    .foregroundStyle(hundredPercent() ? Color.green : Color.red)
                            }
                            .fontWeight(.semibold)
                        }
                    }
                    .listRowBackground(BlurView())
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(nutritionEntry == nil ? "Nutrition Setup" : "Update Goals")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        createNutritionHub()
                    } label: {
                        Text(nutritionEntry == nil ? "Save" : "Update")
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                    }
                    .disabled(!hundredPercent() || currentWeight == 0)
                    .opacity(!hundredPercent() || currentWeight == 0 ? 0.5 : 1)
                }
            }
            .onAppear {
                getUserData()
                if nutritionEntry != nil {
                    getOldHubData()
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
}

#Preview {
    NutritionSetupView()
}
