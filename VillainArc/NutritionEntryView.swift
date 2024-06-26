import SwiftUI
import SwiftData

struct NutritionEntryView: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [NutritionEntry]
    @Binding var date: Date
    @State private var nutritionEntry: NutritionEntry?
    
    private var firstDate: Date? {
        entries.map { $0.date }.sorted().first
    }
    
    private var lastDate: Date? {
        entries.map { $0.date }.sorted().last
    }
    
    private func fetchNutritionEntry() {
        if let entry = entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            nutritionEntry = entry
        } else {
            nutritionEntry = nil
        }
    }
    
    private func changeDate(by days: Int) {
        guard let newDate = Calendar.current.date(byAdding: .day, value: days, to: date) else { return }
        if let first = firstDate, newDate < first {
            date = first
        } else if let last = lastDate, newDate > last {
            date = last
        } else {
            date = newDate
        }
        fetchNutritionEntry()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                ScrollView {
                    if let entry = nutritionEntry {
                        VStack {
                            Text("Calories: \(entry.caloriesConsumed) / \(entry.caloriesGoal)")
                            Text("Protein: \(entry.proteinConsumed) / \(entry.proteinGoal) g")
                            Text("Carbs: \(entry.carbsConsumed) / \(entry.carbsGoal) g")
                            Text("Fat: \(entry.fatConsumed) / \(entry.fatGoal) g")
                        }
                        .padding()
                    } else {
                        Text("No entry for this date.")
                            .padding()
                    }
                }
                .scrollContentBackground(.hidden)
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
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        }
        .onAppear(perform: fetchNutritionEntry)
    }
}

#Preview {
    NutritionEntryView(date: .constant(Calendar.current.startOfDay(for: Date())))
}
