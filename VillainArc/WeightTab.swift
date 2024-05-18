import SwiftUI
import SwiftData
import Charts

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

    private func filteredEntries() -> [WeightEntry] {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -6, to: now)!
        
        return weightEntries.filter { $0.date >= startDate && $0.date <= now }
    }

    private func averageWeightsPerDay() -> [(date: Date, weight: Double)] {
        let entries = filteredEntries()
        let calendar = Calendar.current
        
        var dailyAverages: [(date: Date, weight: Double)] = []
        let groupedByDay = Dictionary(grouping: entries, by: { calendar.startOfDay(for: $0.date) })
        
        for (date, entries) in groupedByDay {
            let totalWeight = entries.reduce(0) { $0 + $1.weight }
            let averageWeight = totalWeight / Double(entries.count)
            dailyAverages.append((date: date, weight: averageWeight))
        }
        
        return dailyAverages.sorted { $0.date < $1.date }
    }

    private func yAxisRange() -> ClosedRange<Double> {
        let averages = averageWeightsPerDay()
        guard let minWeight = averages.min(by: { $0.weight < $1.weight })?.weight,
              let maxWeight = averages.max(by: { $0.weight < $1.weight })?.weight else {
            return 0...100
        }
        return (minWeight - 10)...(maxWeight + 10)
    }

    private func xAxisDates() -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 1
        let startOfWeek = calendar.date(from: components)!

        return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: startOfWeek)! }
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    Chart {
                        ForEach(averageWeightsPerDay(), id: \.date) { entry in
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("Weight", entry.weight)
                            )
                            PointMark(
                                x: .value("Date", entry.date),
                                y: .value("Weight", entry.weight)
                            )
                        }

                        ForEach(xAxisDates(), id: \.self) { date in
                            RuleMark(x: .value("Date", date))
                                .foregroundStyle(Color.clear)
                        }
                    }
                    .chartXScale(domain: xAxisDates().first!...xAxisDates().last!)
                    .chartYScale(domain: yAxisRange())
                    .chartXAxis {
                        AxisMarks(values: xAxisDates()) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel() {
                                let date = value.as(Date.self)!
                                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                            }
                        }
                    }
                    .frame(height: 300)
                }

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
