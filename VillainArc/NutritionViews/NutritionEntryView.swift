import SwiftUI
import SwiftData

struct NutritionEntryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \NutritionEntry.date, animation: .smooth) private var entries: [NutritionEntry]
    @State private var date = Calendar.current.startOfDay(for: Date())
    
    private var firstDate: Date? {
        entries.map { $0.date }.sorted().first
    }
    private var lastDate: Date? {
        entries.map { $0.date }.sorted().last
    }
    
    private func changeDate(by days: Int) {
        guard !entries.isEmpty else { return }
        
        let sortedDates = entries.map { $0.date }.sorted()
        
        guard let currentIndex = sortedDates.firstIndex(of: date) else { return }
        
        let newIndex = currentIndex + days
        
        if newIndex >= 0 && newIndex < sortedDates.count {
            date = sortedDates[newIndex]
        } else if newIndex < 0 {
            date = sortedDates.first!
        } else if newIndex >= sortedDates.count {
            date = sortedDates.last!
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                TabView(selection: $date) {
                    ForEach(entries) { entry in
                        NutritionEntryDataView(entry: entry)
                            .tag(entry.date)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("\(date.formatted(.dateTime.month().day().year()))")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { changeDate(by: -1) }) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(date == firstDate)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { changeDate(by: 1) }) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(date == lastDate)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct NutritionEntryDataView: View {
    enum DisplayedMacros: String {
        case cals = "cals"
        case protein = "protein"
        case carbs = "carbs"
        case fat = "fat"
    }
    var entry: NutritionEntry
    @State private var selectedMacro: DisplayedMacros = .cals
    
    private func totalMacro(for category: String) -> Double {
        switch selectedMacro {
        case .cals:
            entry.foods?
                .filter { $0.mealCategory == category }
                .reduce(0) { $0 + ($1.calories * $1.servingsCount) } ?? 0
        case .protein:
            entry.foods?
                .filter { $0.mealCategory == category }
                .reduce(0) { $0 + ($1.protein * $1.servingsCount) } ?? 0
        case .carbs:
            entry.foods?
                .filter { $0.mealCategory == category }
                .reduce(0) { $0 + ($1.carbs * $1.servingsCount) } ?? 0
        case .fat:
            entry.foods?
                .filter { $0.mealCategory == category }
                .reduce(0) { $0 + ($1.fat * $1.servingsCount) } ?? 0
        }
    }
    
    private func macroDouble(for food: NutritionFood) -> Double {
        switch selectedMacro {
        case .cals:
            food.calories
        case .protein:
            food.protein
        case .carbs:
            food.carbs
        case .fat:
            food.fat
        }
    }
    
    var body: some View {
        ScrollView {
            HStack {
                Text("Calories")
                    .foregroundStyle(Color.secondary)
                Spacer()
                Text("\(Int(entry.caloriesConsumed)) / \(Int(entry.caloriesGoal))")
            }
            .fontWeight(.semibold)
            .customStyle()
            .onTapGesture {
                withAnimation {
                    selectedMacro = .cals
                }
            }
            HStack {
                VStack(alignment: .center, spacing: 0) {
                    Text("Protein")
                        .foregroundStyle(selectedMacro == .protein ? Color.green : Color.secondary)
                    Text("\(Int(entry.proteinConsumed)) / \(Int(entry.proteinGoal)) g")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.thickMaterial, in: .rect(cornerRadius: 12))
                .onTapGesture {
                    withAnimation {
                        if selectedMacro != .protein {
                            selectedMacro = .protein
                        } else {
                            selectedMacro = .cals
                        }
                    }
                }
                VStack(alignment: .center, spacing: 0) {
                    Text("Carbs")
                        .foregroundStyle(selectedMacro == .carbs ? Color.green : Color.secondary)
                    Text("\(Int(entry.carbsConsumed)) / \(Int(entry.proteinGoal)) g")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.thickMaterial, in: .rect(cornerRadius: 12))
                .onTapGesture {
                    withAnimation {
                        if selectedMacro != .carbs {
                            selectedMacro = .carbs
                        } else {
                            selectedMacro = .cals
                        }
                    }
                }
                VStack(alignment: .center, spacing: 0) {
                    Text("Fat")
                        .foregroundStyle(selectedMacro == .fat ? Color.green : Color.secondary)
                    Text("\(Int(entry.fatConsumed)) / \(Int(entry.fatGoal)) g")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.thickMaterial, in: .rect(cornerRadius: 12))
                .onTapGesture {
                    withAnimation {
                        if selectedMacro != .fat {
                            selectedMacro = .fat
                        } else {
                            selectedMacro = .cals
                        }
                    }
                }
            }
            .padding(.horizontal)
            ForEach(entry.mealCategories, id: \.self) { category in
                VStack(spacing: 0) {
                    HStack {
                        Text(category)
                            .font(.title3)
                        Spacer()
                        Text("\(formattedDouble(totalMacro(for: category))) \(selectedMacro == .cals ? "cals" : "g")")
                            .foregroundStyle(selectedMacro == .cals ? Color.secondary : Color.green)
                            .font(.subheadline)
                    }
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                    .padding(.bottom, 3)
                    ForEach(entry.foods!.filter { $0.mealCategory == category }.sorted { $0.date < $1.date }) { food in
                        NavigationLink(destination: {
                            EditEntryFoodView(food: food, entry: entry)
                        }, label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(food.name)
                                    Text(food.brand)
                                        .foregroundStyle(Color.secondary)
                                        .font(.subheadline)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 0) {
                                    Text("\(formattedDouble(macroDouble(for: food) * food.servingsCount)) \(selectedMacro == .cals ? "cals" : "g")")
                                    Text("\(formattedDouble(food.servingSizeDigit * food.servingsCount)) \(food.servingSizeUnit)")
                                }
                                .foregroundStyle(Color.secondary)
                                .font(.subheadline)
                            }
                            .fontWeight(.semibold)
                        })
                        .customStyle()
                    }
                    NavigationLink(destination: {
                        AddFoodView(entry: entry, category: category)
                    }, label: {
                        HStack {
                            Label("Add Food", systemImage: "plus")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    })
                    .customStyle()
                }
                .padding(.vertical, 10)
            }
        }
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    NutritionEntryView()
}
