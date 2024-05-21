import SwiftUI
import SwiftData
import Charts

struct WeightGraphView: View {
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    
    private func yAxisRange() -> ClosedRange<Double> {
        let filteredEntries = filteredEntries()
        guard let minWeight = filteredEntries.map({ $0.weight }).min(),
              let maxWeight = filteredEntries.map({ $0.weight }).max() else {
            return 0...100
        }
        return (minWeight - 10)...(maxWeight + 10)
    }
    private func xAxisRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -6, to: today)!
        let endDate = calendar.date(byAdding: .day, value: 1, to: today)!
        return startDate...endDate
    }
    private func filteredEntries() -> [WeightEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -6, to: today)!
        let endDate = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return weightEntries.filter { $0.date >= startDate && $0.date < endDate }
    }
    private func graphableEntries() -> [(date: Date, weight: Double)] {
        let calendar = Calendar.current
        let entries = filteredEntries()
        var averages: [(date: Date, weight: Double)] = []
        
        let groupedByDay = Dictionary(grouping: entries, by: { calendar.startOfDay(for: $0.date) })
        
        for (date, entries) in groupedByDay {
            let totalWeight = entries.reduce(0) { $0 + $1.weight }
            let averageWeight = totalWeight / Double(entries.count)
            let startOfDay = calendar.startOfDay(for: date)
            averages.append((date: startOfDay, weight: averageWeight))
        }
        
        return averages.sorted { $0.date < $1.date }
    }
    
    var body: some View {
    
        Chart(graphableEntries(), id: \.date) { weightEntry in
            LineMark(
                x: .value("Date", weightEntry.date),
                y: .value("Weight", weightEntry.weight)
            )
            PointMark(
                x: .value("Date", weightEntry.date),
                y: .value("Weight", weightEntry.weight)
            )
        }
        .chartYScale(domain: yAxisRange())
        .chartXScale(domain: xAxisRange())
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 7))
        }
        
    }
}

#Preview {
    WeightGraphView()
}
