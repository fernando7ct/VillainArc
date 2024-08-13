import SwiftUI
import SwiftData

struct NutritionEntryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \NutritionEntry.date, order: .reverse) private var entries: [NutritionEntry]
    @Binding var date: Date
    @Binding var path: NavigationPath
    @State private var updateMealNames = false
    @State private var updateGoals = false
    
    var firstDate: Date? {
        entries.map { $0.date }.sorted().first
    }
    var lastDate: Date? {
        entries.map { $0.date }.sorted().last
    }
    var selectedEntry: NutritionEntry {
        entries.first(where: { $0.date == date }) ?? entries.first!
    }
    var todaysEntry: NutritionEntry {
        entries.first(where: { $0.date == .now.startOfDay })!
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
        NavigationStack(path: $path) {
            ZStack {
                BackgroundView()
                NutritionEntryDataView(entry: selectedEntry)
            }
            .navigationDestination(for: FoodCategory.self) { value in
                AddFoodView(entry: value.entry, category: value.category)
            }
            .navigationDestination(for: FoodEntry.self) { value in
                EditEntryFoodView(food: value.food, entry: value.entry)
            }
            .navigationDestination(for: FoodEntryCategoryFirebase.self) { value in
                FoodToEntryView(food: value.food, entry: value.entry, category: value.category, isFirebaseFood: value.firebase)
            }
            .safeAreaInset(edge: .top) {
                HStack {
                    Text(date, format: .dateTime.month().day().year())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    Button {
                        withAnimation(.snappy) {
                            changeDate(by: -1)
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(7)
                            .background(.ultraThinMaterial, in: .circle)
                    }
                    .disabled(date == firstDate)
                    .padding(.trailing, 5)
                    Button {
                        withAnimation(.snappy) {
                            changeDate(by: 1)
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(7)
                            .background(.ultraThinMaterial, in: .circle)
                    }
                    .disabled(date == lastDate)
                    Menu {
                        Button {
                            updateGoals.toggle()
                        } label: {
                            Label("Update Goals", systemImage: "chart.pie.fill")
                        }
                        Button {
                            updateMealNames.toggle()
                        } label: {
                            Label("Change Meal Names", systemImage: "square.fill.text.grid.1x2")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(10)
                            .background(.ultraThinMaterial, in: .circle)
                    }
                }
                .padding()
                .sheet(isPresented: $updateMealNames) {
                    UpdateMealNamesView(entry: todaysEntry)
                }
                .sheet(isPresented: $updateGoals) {
                    NutritionSetupView(nutritionEntry: todaysEntry)
                }
            }
        }
    }
}

struct FoodCategory: Hashable {
    var entry: NutritionEntry
    var category: String
    
    init(entry: NutritionEntry, category: String) {
        self.entry = entry
        self.category = category
    }
}
struct FoodEntry: Hashable {
    var food: NutritionFood
    var entry: NutritionEntry
    
    init(food: NutritionFood, entry: NutritionEntry) {
        self.food = food
        self.entry = entry
    }
}
struct FoodEntryCategoryFirebase: Hashable {
    var food: NutritionFood
    var entry: NutritionEntry
    var category: String
    var firebase: Bool
    
    init(food: NutritionFood, entry: NutritionEntry, category: String, firebase: Bool) {
        self.food = food
        self.entry = entry
        self.category = category
        self.firebase = firebase
    }
}

struct NutritionEntryDataView: View {
    @Environment(\.modelContext) private var context
    @State private var showNotes = false
    @State private var tempNotes = ""
    
    enum DisplayedMacros: String {
        case cals = "cals"
        case protein = "protein"
        case carbs = "carbs"
        case fat = "fat"
    }
    @Bindable var entry: NutritionEntry
    @State private var selectedMacro: DisplayedMacros = .cals
    
    private func totalMacro(for category: String) -> Double {
        switch selectedMacro {
        case .cals:
            entry.foods
                .filter { $0.mealCategory == category }
                .reduce(0) { $0 + ($1.calories * $1.servingsCount) }
        case .protein:
            entry.foods
                .filter { $0.mealCategory == category }
                .reduce(0) { $0 + ($1.protein * $1.servingsCount) }
        case .carbs:
            entry.foods
                .filter { $0.mealCategory == category }
                .reduce(0) { $0 + ($1.carbs * $1.servingsCount) }
        case .fat:
            entry.foods
                .filter { $0.mealCategory == category }
                .reduce(0) { $0 + ($1.fat * $1.servingsCount) }
        }
    }
    private func updateEntryNotes() {
        entry.notes = tempNotes
        tempNotes.removeAll()
        DataManager.shared.updateNutritionEntryNotes(entry: entry)
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
            .scrollTransition { content, phase in
                content
                    .blur(radius: phase.isIdentity ? 0 : 1.5)
                    .opacity(phase.isIdentity ? 1 : 0.7)
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
                    Text("\(Int(entry.carbsConsumed)) / \(Int(entry.carbsGoal)) g")
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
            .scrollTransition { content, phase in
                content
                    .blur(radius: phase.isIdentity ? 0 : 1.5)
                    .opacity(phase.isIdentity ? 1 : 0.7)
            }
            ForEach(entry.mealCategories, id: \.self) { category in
                if !category.isEmpty {
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
                        ForEach(entry.foods.filter { $0.mealCategory == category }.sorted { $0.date < $1.date }) { food in
                            NavigationLink(value: FoodEntry(food: food, entry: entry)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(food.name)
                                            .lineLimit(1)
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
                            }
                            .customStyle()
                            .contextMenu {
                                Button(role: .destructive) {
                                    withAnimation {
                                        DataManager.shared.deleteEntryFood(entry: entry, food: food, context: context)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                            }
                        }
                        NavigationLink(value: FoodCategory(entry: entry, category: category)) {
                            HStack {
                                Label("Add Food", systemImage: "plus")
                                    .fontWeight(.semibold)
                            }
                            .hSpacing(.leading)
                        }
                        .customStyle()
                    }
                    .padding(.vertical, 10)
                    .scrollTransition { content, phase in
                        content
                            .blur(radius: phase.isIdentity ? 0 : 1.5)
                            .opacity(phase.isIdentity ? 1 : 0.7)
                    }
                }
            }
            Button {
                showNotes.toggle()
            } label: {
                HStack {
                    Text("Notes: \(entry.notes.isEmpty ? "Click to Add" : entry.notes)")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .hSpacing(.leading)
                .customStyle()
            }
            .scrollTransition { content, phase in
                content
                    .blur(radius: phase.isIdentity ? 0 : 1.5)
                    .opacity(phase.isIdentity ? 1 : 0.7)
            }
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showNotes, onDismiss: updateEntryNotes) {
            NavigationView {
                ZStack {
                    BackgroundView()
                    Form {
                        TextField("Notes", text: $tempNotes, axis: .vertical)
                            .listRowBackground(BlurView())
                    }
                    .scrollContentBackground(.hidden)
                }
                .navigationTitle("Notes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .onTapGesture {
                    hideKeyboard()
                }
                .onAppear {
                    tempNotes = entry.notes
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showNotes = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .fontWeight(.semibold)
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .scrollContentBackground(.hidden)
    }
}
