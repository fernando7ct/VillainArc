import SwiftUI
import SwiftData
import CodeScanner

struct AddFoodView: View {
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
            }
        }
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
            List {
                ForEach(foods) { food in
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
                Button {
                    isShowingScanner = true
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                }
            }
        }
    }
}
