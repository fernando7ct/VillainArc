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
    var entry: NutritionEntry
    
    private func totalCalories(for category: String) -> Double {
        entry.foods?
            .filter { $0.mealCategory == category }
            .reduce(0) { $0 + ($1.calories * $1.servingsCount) } ?? 0
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
            HStack {
                VStack(alignment: .center, spacing: 0) {
                    Text("Protein")
                        .foregroundStyle(Color.secondary)
                    Text("\(Int(entry.proteinConsumed)) / \(Int(entry.proteinGoal)) g")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.thickMaterial, in: .rect(cornerRadius: 12))
                VStack(alignment: .center, spacing: 0) {
                    Text("Carbs")
                        .foregroundStyle(Color.secondary)
                    Text("\(Int(entry.carbsConsumed)) / \(Int(entry.proteinGoal)) g")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.thickMaterial, in: .rect(cornerRadius: 12))
                VStack(alignment: .center, spacing: 0) {
                    Text("Fat")
                        .foregroundStyle(Color.secondary)
                    Text("\(Int(entry.fatConsumed)) / \(Int(entry.fatGoal)) g")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.thickMaterial, in: .rect(cornerRadius: 12))
            }
            .padding(.horizontal)
            ForEach(entry.mealCategories, id: \.self) { category in
                VStack(spacing: 0) {
                    HStack {
                        Text(category)
                            .font(.title3)
                        Spacer()
                        Text("\(formattedDouble(totalCalories(for: category))) cals")
                            .foregroundStyle(Color.secondary)
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
                                    Text("\(formattedDouble(food.calories * food.servingsCount)) cals")
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
