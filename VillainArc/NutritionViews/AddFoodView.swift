import SwiftUI
import SwiftData
import CodeScanner

struct AddFoodView: View {
    @Environment(\.modelContext) private var context
    @State var entry: NutritionEntry
    @State var category: String
    @State private var name = ""
    @Query(filter: #Predicate<NutritionFood> { food in
        food.entry == nil
    }, sort: \NutritionFood.date, order: .reverse, animation: .smooth) private var foods: [NutritionFood]
    @State private var isShowingScanner = false
    @State private var scanResult: String? = nil
    @State private var nutritionFood: NutritionFood?
    @State private var showAlert = false
    @State private var createFoodSheet = false
    @State private var createFoodSheet2 = false
    @State private var addFoodSheet = false
    
    private func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        switch result {
        case .success(let result):
            scanResult = result.string
            DataManager.shared.fetchNutritionFood(barcode: scanResult!) { food in
                if let food = food {
                    nutritionFood = food
                    addFoodSheet = true
                } else {
                    showAlert = true
                }
            }
        case .failure(let error):
            scanResult = "Scanning Failed: \(error.localizedDescription)"
        }
    }
    
    private func deleteFood(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let foodToDelete = foods[index]
                DataManager.shared.deleteFood(food: foodToDelete, context: context)
            }
        }
    }
    
    private func tokenize(_ text: String) -> [String] {
        return text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    }
    
    private func fuzzyMatch(_ text: String, with searchTokens: [String]) -> Bool {
        let tokens = tokenize(text)
        for searchToken in searchTokens {
            if !tokens.contains(where: { $0.contains(searchToken) || levenshteinDistance($0, searchToken) <= 2 }) {
                return false
            }
        }
        return true
    }
    
    private func levenshteinDistance(_ lhs: String, _ rhs: String) -> Int {
        let lhsCount = lhs.count
        let rhsCount = rhs.count
        var matrix = Array(repeating: Array(repeating: 0, count: rhsCount + 1), count: lhsCount + 1)
        
        for i in 0...lhsCount { matrix[i][0] = i }
        for j in 0...rhsCount { matrix[0][j] = j }
        
        for i in 1...lhsCount {
            for j in 1...rhsCount {
                if lhs[lhs.index(lhs.startIndex, offsetBy: i - 1)] == rhs[rhs.index(rhs.startIndex, offsetBy: j - 1)] {
                    matrix[i][j] = matrix[i - 1][j - 1]
                } else {
                    matrix[i][j] = min(
                        matrix[i - 1][j] + 1,
                        matrix[i][j - 1] + 1,
                        matrix[i - 1][j - 1] + 1
                    )
                }
            }
        }
        return matrix[lhsCount][rhsCount]
    }
    
    var filteredFoods: [NutritionFood] {
        let searchTokens = tokenize(name)
        
        if searchTokens.isEmpty {
            return foods
        } else {
            return foods.filter { food in
                fuzzyMatch(food.name, with: searchTokens) || fuzzyMatch(food.brand, with: searchTokens)
            }
        }
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
            List {
                ForEach(filteredFoods) { food in
                    NavigationLink(destination: FoodToEntryView(food: food, entry: entry, category: category), label: {
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
                    .listRowBackground(BlurView())
                }
                .onDelete(perform: deleteFood)
            }
            .scrollContentBackground(.hidden)
            .searchable(text: $name)
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(codeTypes: [.ean13], completion: handleScan)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Food Not Found"),
                    message: Text("The food with the scanned barcode was not found. Would you like to create it?"),
                    primaryButton: .default(Text("Yes")) {
                        createFoodSheet = true
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $createFoodSheet) {
                CreateFoodView(barcode: scanResult!)
            }
            .sheet(item: $nutritionFood) { food in
                AddFirebaseFoodView(food: food, entry: entry, category: category)
            }
        }
        .navigationTitle(category)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarTitleMenu {
            Picker("", selection: $category) {
                ForEach(entry.mealCategories, id: \.self) { category in
                    Text(category).tag(category)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        isShowingScanner = true
                    } label: {
                        Label("Scan", systemImage: "qrcode.viewfinder")
                    }
                    Button {
                        createFoodSheet2 = true
                    } label: {
                        Label("Create Food", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .sheet(isPresented: $createFoodSheet2) {
                    CreateFoodView(barcode: "")
                }
            }
        }
    }
}
