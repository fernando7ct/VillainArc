import SwiftUI
import SwiftData
import Charts

struct WeightGraphView: View {
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @State private var selectedWeightRange: weightGraphRange = .week
    
    enum weightGraphRange {
        case day
        case week
        case month
        case sixMonths
    }
    
    private func yAxisRange() -> ClosedRange<Double> {
        let filteredEntries = filteredEntries()
        guard let minWeight = filteredEntries.map({ $0.weight }).min(),
              let maxWeight = filteredEntries.map({ $0.weight }).max() else {
            return 0...100
        }
        return (minWeight < 10 ? 0 : minWeight - 10)...(maxWeight + 10)
    }
    
    private func xAxisRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let (startDate, endDate): (Date, Date) = {
            switch selectedWeightRange {
            case .day:
                let start = calendar.startOfDay(for: today)
                let end = calendar.date(byAdding: .day, value: 1, to: start)!
                return (start, end)
            case .week:
                let start = calendar.date(byAdding: .day, value: -6, to: today)!
                let end = calendar.date(byAdding: .day, value: 1, to: today)!
                return (start, end)
            case .month:
                let start = calendar.date(byAdding: .day, value: -28, to: today)!
                let end = calendar.date(byAdding: .day, value: 7, to: today)!
                return (start, end)
            case .sixMonths:
                let startOfPrevious5thMonth = calendar.date(byAdding: .month, value: -5, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
                let endOfCurrentMonth = calendar.date(byAdding: .month, value: 1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
                return (startOfPrevious5thMonth, endOfCurrentMonth)
            }
        }()
        return startDate...endDate
    }
    
    private func filteredEntries() -> [WeightEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let (startDate, endDate): (Date, Date) = {
            switch selectedWeightRange {
            case .day:
                let start = calendar.startOfDay(for: today)
                let end = calendar.date(byAdding: .day, value: 1, to: start)!
                return (start, end)
            case .week:
                let start = calendar.date(byAdding: .day, value: -6, to: today)!
                let end = calendar.date(byAdding: .day, value: 1, to: today)!
                return (start, end)
            case .month:
                let start = calendar.date(byAdding: .day, value: -28, to: today)!
                let end = calendar.date(byAdding: .day, value: 1, to: today)!
                return (start, end)
            case .sixMonths:
                let start = calendar.date(byAdding: .month, value: -5, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
                let end = calendar.date(byAdding: .month, value: 1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
                return (start, end)
            }
        }()
        
        return weightEntries.filter { $0.date >= startDate && $0.date < endDate }
    }
    
    private func graphableEntries() -> [(date: Date, weight: Double)] {
        let calendar = Calendar.current
        let entries = filteredEntries()
        var averages: [(date: Date, weight: Double)] = []
        
        if selectedWeightRange == .sixMonths {
            let groupedByWeek = Dictionary(grouping: entries, by: { calendar.dateInterval(of: .weekOfYear, for: $0.date)!.start })
            for (startOfWeek, entries) in groupedByWeek {
                let totalWeight = entries.reduce(0) { $0 + $1.weight }
                let averageWeight = totalWeight / Double(entries.count)
                averages.append((date: startOfWeek, weight: averageWeight))
            }
        } else if selectedWeightRange == .day {
            let groupedByMinute = Dictionary(grouping: entries, by: { calendar.dateInterval(of: .minute, for: $0.date)!.start })
            for (startOfMinute, entries) in groupedByMinute {
                let totalWeight = entries.reduce(0) { $0 + $1.weight }
                let averageWeight = totalWeight / Double(entries.count)
                averages.append((date: startOfMinute, weight: averageWeight))
            }
        } else {
            let groupedByDay = Dictionary(grouping: entries, by: { calendar.startOfDay(for: $0.date) })
            for (date, entries) in groupedByDay {
                let totalWeight = entries.reduce(0) { $0 + $1.weight }
                let averageWeight = totalWeight / Double(entries.count)
                let startOfDay = calendar.startOfDay(for: date)
                averages.append((date: startOfDay, weight: averageWeight))
            }
        }
        
        return averages.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack {
            Picker("Time Range", selection: $selectedWeightRange) {
                Text("Day").tag(weightGraphRange.day)
                Text("Week").tag(weightGraphRange.week)
                Text("Month").tag(weightGraphRange.month)
                Text("6 Months").tag(weightGraphRange.sixMonths)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom)
            
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
                if selectedWeightRange == .day {
                    AxisMarks(values: [
                        Calendar.current.startOfDay(for: Date()),
                        Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date())!,
                        Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!,
                        Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!
                    ]) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.hour().minute())
                    }
                } else if selectedWeightRange == .week {
                    AxisMarks(values: .automatic(desiredCount: 7)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                } else if selectedWeightRange == .month {
                    AxisMarks(values: .stride(by: .day, count: 7))
                } else {
                    AxisMarks(values: .stride(by: .month, count: 1)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month())
                    }
                }
            }
        }
    }
}

#Preview {
    WeightGraphView()
}
