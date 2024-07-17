import SwiftUI
import SwiftData

struct UpdateMealNamesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var mealNames: [String] = ["", "", "", "", "", ""]
    @Bindable var entry: NutritionEntry
    
    private func getMealNames() {
        let descriptor = FetchDescriptor<NutritionHub>()
        let hub = try? context.fetch(descriptor)
        guard let first = hub?.first else {
            return
        }
        mealNames = first.mealCategories
    }
    
    private func updateNames() {
        DataManager.shared.updateNutritionMealNames(entry: entry, mealNames: mealNames, context: context)
        dismiss()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                Form {
                    ForEach(mealNames.indices, id: \.self) { index in
                        HStack {
                            TextField("Meal \(index + 1) Name", text: $mealNames[index])
                            Spacer()
                            Text("Meal \(index + 1)")
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                        }
                        .listRowBackground(BlurView())
                        .listRowSeparator(.hidden)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        updateNames()
                    } label: {
                        Text("Update")
                            .fontWeight(.semibold)
                    }
                    .tint(.green)
                    .disabled(mealNames.allSatisfy { $0.isEmpty })
                }
            }
            .navigationTitle("Meal Names")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .onTapGesture {
                hideKeyboard()
            }
            .onAppear {
                getMealNames()
            }
        }
    }
}
