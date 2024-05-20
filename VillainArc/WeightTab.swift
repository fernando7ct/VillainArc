import SwiftUI
import SwiftData

struct WeightTab: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @State private var addWeightSheetActive = false

    private func deleteWeightEntry(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let weightEntryToDelete = weightEntries[index]
                DataManager.shared.deleteWeightEntry(weightEntry: weightEntryToDelete, context: context)
            }
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(weightEntries, id: \.self) { weightEntry in
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .font(.title2)
                            .foregroundStyle(.purple)
                        Text("\(formattedWeight(weightEntry.weight)) lbs")
                            .fontWeight(.semibold)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(weightEntry.date.formatted(.dateTime.day().month().year()))")
                            Text("\(weightEntry.date.formatted(.dateTime.hour().minute()))")
                        }
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                    }
                }
                .onDelete(perform: deleteWeightEntry)
            }
            .navigationTitle("Weight")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        addWeightSheetActive = true
                    }, label: {
                        Image(systemName: "plus")
                    })
                    .sheet(isPresented: $addWeightSheetActive) {
                        AddWeightEntryView()
                    }
                }
            }
        }
    }
}

#Preview {
    WeightTab()
}
