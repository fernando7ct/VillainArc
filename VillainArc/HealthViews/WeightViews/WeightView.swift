import SwiftUI
import Charts
import SwiftData

struct WeightView: View {
    @Query(sort: \WeightEntry.date, order: .forward) private var weightEntries: [WeightEntry]
    @State private var addWeightSheetActive = false
    @State private var selectedRange: GraphRanges = .month
    @State private var selectedDate: Date? = nil
    @State private var selectedWeekday: String? = nil
    
    var filteredEntries: [WeightEntry] {
        let calendar = Calendar.current
        var startDate: Date {
            switch selectedRange {
            case .week:
                calendar.date(byAdding: .day, value: -7, to: .now.startOfDay)!
            case .month:
                calendar.date(byAdding: .month, value: -1, to: .now.startOfDay)!
            case .sixMonths:
                calendar.date(byAdding: .month, value: -6, to: .now.startOfDay)!
            case .year:
                calendar.date(byAdding: .year, value: -1, to: .now.startOfDay)!
            case .all:
                    .distantPast
            }
        }
        return weightEntries.filter({ $0.date >= startDate })
    }
    var averageWeight: Double {
        guard !weightEntries.isEmpty else { return 0 }
        return filteredEntries.reduce(0) { $0 + $1.weight } / Double(filteredEntries.count)
    }
    var averageWeightChangePerWeekday: [(day: String, change: Double)] {
        let calendar = Calendar.current
        var changeList: [(date: Date, change: Double)] = []
        for i in 1..<weightEntries.count {
            changeList.append((date: weightEntries[i - 1].date, change: weightEntries[i] - weightEntries[i - 1]))
        }
        let groupedEntries = Dictionary(grouping: changeList) { calendar.component(.weekday, from: $0.date) }
        return (1...7).compactMap { weekday -> (String, Double)? in
            if let entries = groupedEntries[weekday] {
                let averageChange = entries.reduce(0) { $0 + $1.change } / Double(entries.count)
                return (calendar.weekdaySymbols[weekday - 1], averageChange)
            } else {
                return (calendar.weekdaySymbols[weekday - 1], 0)
            }
        }
    }

    var averageWeightChangePerWeek: Double {
        guard !averageWeightChangePerWeekday.isEmpty else { return 0 }
        return averageWeightChangePerWeekday.reduce(0) { $0 + $1.change }
    }
    private func yAxisRange() -> ClosedRange<Double> {
        guard let minWeight = weightEntries.map({ $0.weight }).min(),
              let maxWeight = weightEntries.map({ $0.weight }).max() else {
            return 0...100
        }
        return (minWeight < 5 ? 0 : minWeight - 5)...(maxWeight + 5)
    }
    private func yAxisRange2() -> ClosedRange<Double> {
        guard let minChange = averageWeightChangePerWeekday.map({ $0.change }).min(),
              let maxChange = averageWeightChangePerWeekday.map({ $0.change }).max() else {
            return -1...1
        }
        return (minChange - 0.5)...(maxChange + 0.5)
    }
    private func xAxisRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let endDate = Date.now
        let startDate: Date
        
        if weightEntries.isEmpty {
            startDate = endDate.startOfDay
        } else {
            let oldestEntryDate = weightEntries.map { $0.date }.min()!
            switch selectedRange {
            case .week:
                let weekStartDate = calendar.date(byAdding: .day, value: -7, to: endDate.startOfDay)!
                startDate = max(weekStartDate, oldestEntryDate)
            case .month:
                let monthStartDate = calendar.date(byAdding: .month, value: -1, to: endDate.startOfDay)!
                startDate = max(monthStartDate, oldestEntryDate)
            case .sixMonths:
                let sixMonthsStartDate = calendar.date(byAdding: .month, value: -6, to: endDate.startOfDay)!
                startDate = max(sixMonthsStartDate, oldestEntryDate)
            case .year:
                let yearStartDate = calendar.date(byAdding: .year, value: -1, to: endDate.startOfDay)!
                startDate = max(yearStartDate, oldestEntryDate)
            case .all:
                startDate = oldestEntryDate
            }
        }
        return startDate...endDate
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    if !weightEntries.isEmpty {
                        if let today = weightEntries.first(where: { $0.date.isSameDayAs(.now) }) {
                            Text("Today")
                                .foregroundStyle(.secondary)
                                .textScale(.secondary)
                            Text("\(formattedDouble(today.weight)) lbs")
                                .font(.title)
                        } else if let mostRecent = weightEntries.last {
                            Text(mostRecent.date, format: .dateTime.month().day().year())
                                .foregroundStyle(.secondary)
                                .textScale(.secondary)
                            Text("\(formattedDouble(mostRecent.weight)) lbs")
                                .font(.title)
                        }
                        if filteredEntries.count > 1 {
                            Text("Avg: \(formattedDouble(averageWeight)) lbs")
                                .foregroundStyle(.secondary)
                                .textScale(.secondary)
                                .fontWeight(.none)
                        }
                    } else {
                        Text("No Data")
                            .font(.title)
                    }
                }
                .fontWeight(.semibold)
                .hSpacing(.leading)
                .scrollTransition { content, phase in
                    content
                        .blur(radius: phase.isIdentity ? 0 : 1.5)
                        .opacity(phase.isIdentity ? 1 : 0.7)
                }
                
                Chart(filteredEntries) { entry in
                    AreaMark(x: .value("Date", entry.date), yStart: .value("Weight", yAxisRange().lowerBound), yEnd: .value("Weight", entry.weight))
                        .foregroundStyle(Color.blue.opacity(0.6))
                        .interpolationMethod(.monotone)
                    LineMark(x: .value("Date", entry.date), y: .value("Weight", entry.weight))
                        .foregroundStyle(Color.blue)
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                    if let selectedDate, selectedDate.isSameDayAs(entry.date) {
                        PointMark(x: .value("Date", entry.date), y: .value("Weight", entry.weight))
                            .foregroundStyle(Color.blue)
                        RuleMark(x: .value("Date", entry.date))
                            .foregroundStyle(Color.blue)
                            .lineStyle(StrokeStyle(lineWidth: 1.5))
                            .annotation(position: .top, overflowResolution: .init(x: .fit(to: .plot), y: .fit(to: .chart))) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("\(entry.date.formatted(.dateTime.month().day().year()))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    HStack(alignment: .bottom, spacing: 3) {
                                        Text("\(formattedDouble(entry.weight))")
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                        Text("lbs")
                                            .foregroundStyle(.secondary)
                                            .padding(.bottom, 1)
                                    }
                                }
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.blue.gradient, in: .rect(cornerRadius: 6, style: .continuous))
                            }
                    }
                }
                .chartYScale(domain: yAxisRange())
                .chartXScale(domain: xAxisRange())
                .chartXAxis {}
                .chartXSelection(value: $selectedDate)
                .frame(height: 250)
                .scrollTransition { content, phase in
                    content
                        .blur(radius: phase.isIdentity ? 0 : 1.5)
                        .opacity(phase.isIdentity ? 1 : 0.7)
                }
                
                HStack {
                    Text(xAxisRange().lowerBound, format: .dateTime.month(.abbreviated).day().year())
                    Spacer()
                    Text("Today")
                        .padding(.trailing, 30)
                }
                .textScale(.secondary)
                .foregroundStyle(.secondary)
                .scrollTransition { content, phase in
                    content
                        .blur(radius: phase.isIdentity ? 0 : 1.5)
                        .opacity(phase.isIdentity ? 1 : 0.7)
                }
                
                Picker("Time Range", selection: $selectedRange) {
                    Text("W").tag(GraphRanges.week)
                    Text("M").tag(GraphRanges.month)
                    Text("6M").tag(GraphRanges.sixMonths)
                    Text("Y").tag(GraphRanges.year)
                    Text("All").tag(GraphRanges.all)
                }
                .pickerStyle(.segmented)
                .padding(.top)
                .scrollTransition { content, phase in
                    content
                        .blur(radius: phase.isIdentity ? 0 : 1.5)
                        .opacity(phase.isIdentity ? 1 : 0.7)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 12, style: .continuous))
            .padding(.bottom)
            
            if weightEntries.count > 7 {
                VStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Average Change Per Weekday")
                            .font(.title3)
                        Text("\(averageWeightChangePerWeek > 0 ? "+" : "")\(formattedDouble(averageWeightChangePerWeek)) lbs/week")
                            .foregroundStyle(.secondary)
                            .textScale(.secondary)
                            .fontWeight(.none)
                    }
                    .fontWeight(.semibold)
                    .hSpacing(.leading)
                    .scrollTransition { content, phase in
                        content
                            .blur(radius: phase.isIdentity ? 0 : 1.5)
                            .opacity(phase.isIdentity ? 1 : 0.7)
                    }
                    
                    Chart(averageWeightChangePerWeekday, id: \.day) { day in
                        BarMark(x: .value("Weekday", day.day), yStart: .value("Change", 0), yEnd: .value("Change", day.change))
                            .foregroundStyle(Color.blue.opacity(0.6))
                        if let selectedWeekday, selectedWeekday == day.day {
                            RuleMark(x: .value("Weekday", day.day))
                                .foregroundStyle(Color.clear)
                                .annotation(position: .automatic, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(day.day)
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                        Text("\(day.change > 0 ? "+" : "")\(formattedDouble2(day.change))")
                                            .font(.title3)
                                            .foregroundStyle(day.change > 0 ? Color.green : Color.red)
                                    }
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(.blue.gradient, in: .rect(cornerRadius: 6, style: .continuous))
                                }
                        }
                    }
                    .chartXSelection(value: $selectedWeekday)
                    .chartYScale(domain: yAxisRange2())
                    .chartXAxis {
                        AxisMarks(values: .automatic) { value in
                            AxisValueLabel() {
                                if let day = value.as(String.self) {
                                    Text(day.prefix(3))
                                }
                            }
                        }
                    }
                    .frame(height: 250)
                    .scrollTransition { content, phase in
                        content
                            .blur(radius: phase.isIdentity ? 0 : 1.5)
                            .opacity(phase.isIdentity ? 1 : 0.7)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 12, style: .continuous))
                
                Color.clear
                    .frame(height: 60)
            }

        }
        .padding(.horizontal)
        .vSpacing(.top)
        .safeAreaInset(edge: .top) {
            HStack(spacing: 5) {
                Text("Weight")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                NavigationLink(value: 0) {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(6)
                        .background(.ultraThinMaterial, in: .circle)
                }
                Button {
                    addWeightSheetActive = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(8)
                        .background(.ultraThinMaterial, in: .circle)
                }
                .sheet(isPresented: $addWeightSheetActive) {
                    AddWeightEntryView()
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    NavigationView {
        WeightView()
            .tint(.primary)
    }
}
