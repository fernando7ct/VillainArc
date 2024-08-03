import SwiftUI
import Charts
import SwiftData

struct CaloriesView: View {
    @Query(sort: \HealthEnergy.date, order: .reverse) private var healthEnergy: [HealthEnergy]
    @State private var selectedRange: GraphRanges = .month
    @State private var selectedDate: Date? = nil
    @State private var selectedEntry: HealthEnergy? = nil
    
    private func yAxisRange() -> ClosedRange<Double> {
        guard let maxCalories = filteredCalories.map({ $0.total }).max() else {
            return 0...2000
        }
        return 0...(maxCalories + 500)
    }
    private func xAxisRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let endDate = Date.now.startOfDay
        let startDate: Date
        
        if healthEnergy.isEmpty {
            startDate = endDate.startOfDay
        } else {
            let oldestEntryDate = healthEnergy.map { $0.date }.min()!
            switch selectedRange {
            case .week:
                let weekStartDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
                startDate = max(weekStartDate, oldestEntryDate)
            case .month:
                let monthStartDate = calendar.date(byAdding: .month, value: -1, to: endDate)!
                startDate = max(monthStartDate, oldestEntryDate)
            case .sixMonths:
                let sixMonthsStartDate = calendar.date(byAdding: .month, value: -6, to: endDate)!
                startDate = max(sixMonthsStartDate, oldestEntryDate)
            case .year:
                let yearStartDate = calendar.date(byAdding: .year, value: -1, to: endDate)!
                startDate = max(yearStartDate, oldestEntryDate)
            case .all:
                startDate = oldestEntryDate
            }
        }
        return startDate...endDate
    }
    var filteredCalories: [HealthEnergy] {
        let calendar = Calendar.current
        switch selectedRange {
        case .week:
            let startDate = calendar.date(byAdding: .day, value: -7, to: .now.startOfDay)!
            return healthEnergy.filter({ $0.date >= startDate})
        case .month:
            let startDate = calendar.date(byAdding: .month, value: -1, to: .now.startOfDay)!
            return healthEnergy.filter({ $0.date >= startDate})
        case .sixMonths:
            let startDate = calendar.date(byAdding: .month, value: -6, to: .now.startOfDay)!
            return healthEnergy.filter({ $0.date >= startDate})
        case .year:
            let startDate = calendar.date(byAdding: .year, value: -1, to: .now.startOfDay)!
            return healthEnergy.filter({ $0.date >= startDate})
        case .all:
            return healthEnergy
        }
    }
    var previousFilteredCalories: [HealthEnergy] {
        let calendar = Calendar.current
        switch selectedRange {
        case .week:
            let originalStartDate = calendar.date(byAdding: .day, value: -7, to: .now.startOfDay)!
            let newStartDate = calendar.date(byAdding: .day, value: -7, to: originalStartDate)!
            return healthEnergy.filter({ $0.date < originalStartDate && $0.date >= newStartDate })
        case .month:
            let originalStartDate = calendar.date(byAdding: .month, value: -1, to: .now.startOfDay)!
            let newStartDate = calendar.date(byAdding: .month, value: -1, to: originalStartDate)!
            return healthEnergy.filter({ $0.date < originalStartDate && $0.date >= newStartDate })
        case .sixMonths:
            let originalStartDate = calendar.date(byAdding: .month, value: -6, to: .now.startOfDay)!
            let newStartDate = calendar.date(byAdding: .month, value: -6, to: originalStartDate)!
            return healthEnergy.filter({ $0.date < originalStartDate && $0.date >= newStartDate })
        case .year:
            let originalStartDate = calendar.date(byAdding: .year, value: -1, to: .now.startOfDay)!
            let newStartDate = calendar.date(byAdding: .year, value: -1, to: originalStartDate)!
            return healthEnergy.filter({ $0.date < originalStartDate && $0.date >= newStartDate })
        case .all:
            return []
        }
    }
    var averageCalories: Int {
        guard !healthEnergy.isEmpty else { return 0 }
        return Int(filteredCalories.reduce(0) { $0 + $1.total } / Double(filteredCalories.count))
    }
    var previousAverageCalories: Int {
        guard !healthEnergy.isEmpty else { return 0 }
        return Int(previousFilteredCalories.reduce(0) { $0 + $1.total } / Double(previousFilteredCalories.count))
    }
    
    var body: some View {
        VStack {
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 0) {
                        if !healthEnergy.isEmpty {
                            if let today = healthEnergy.first(where: { $0.date == .now.startOfDay }) {
                                Text("Today")
                                    .foregroundStyle(.secondary)
                                    .textScale(.secondary)
                                Text("\(Int(today.total)) Calories")
                                    .font(.title)
                            } else if let mostRecent = healthEnergy.first {
                                Text(mostRecent.date, format: .dateTime.month().day().year())
                                    .foregroundStyle(.secondary)
                                    .textScale(.secondary)
                                Text("\(Int(mostRecent.total)) Calories")
                                    .font(.title)
                            }
                        } else {
                            Text("No Data")
                                .font(.title)
                        }
                    }
                }
                .hSpacing(.leading)
                .fontWeight(.semibold)
                .padding(.bottom)
                
                Chart(filteredCalories) { day in
                    AreaMark(x: .value("Date", day.date), yStart: .value("Calories", 0), yEnd: .value("Calories", day.total))
                        .foregroundStyle(Color.orange.opacity(0.4))
                        .interpolationMethod(.monotone)
                    LineMark(x: .value("Date", day.date), y: .value("Calories", day.total))
                        .foregroundStyle(Color.orange)
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                    if let selectedEntry {
                        PointMark(x: .value("Date", selectedEntry.date), y: .value("Calories", selectedEntry.total))
                            .foregroundStyle(Color.orange)
                        RuleMark(x: .value("Date", selectedEntry.date))
                            .foregroundStyle(Color.orange)
                            .lineStyle(StrokeStyle(lineWidth: 1.5))
                            .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("\(selectedEntry.date.formatted(.dateTime.month().day().year()))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    HStack(alignment: .bottom, spacing: 3) {
                                        Text("\(Int(selectedEntry.activeEnergy))")
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                        Text("Active")
                                            .foregroundStyle(.secondary)
                                            .padding(.bottom, 1)
                                    }
                                    HStack(alignment: .bottom, spacing: 3) {
                                        Text("\(Int(selectedEntry.total))")
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                        Text("Total")
                                            .foregroundStyle(.secondary)
                                            .padding(.bottom, 1)
                                    }
                                }
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Color.orange.gradient)
                                }
                            }
                    }
                }
                .chartYScale(domain: yAxisRange())
                .chartXScale(domain: xAxisRange())
                .chartXAxis {}
                .chartXSelection(value: $selectedDate)
                .onChange(of: selectedDate) {
                    if let selectedDate {
                        let calendar = Calendar.current
                        let dayComponent = calendar.component(.day, from: selectedDate)
                        let monthComponent = calendar.component(.month, from: selectedDate)
                        let yearComponent = calendar.component(.year, from: selectedDate)
                        if let currentEntry = filteredCalories.first(where: { item in
                            calendar.component(.day, from: item.date) == dayComponent &&
                            calendar.component(.month, from: item.date) == monthComponent &&
                            calendar.component(.year, from: item.date) == yearComponent
                        }) {
                            selectedEntry = currentEntry
                        }
                    } else {
                        selectedEntry = nil
                    }
                }
                .frame(height: 250)
                
                HStack {
                    Text(xAxisRange().lowerBound, format: .dateTime.month(.abbreviated).day().year())
                    Spacer()
                    Text("Today")
                        .padding(.trailing, 40)
                }
                .textScale(.secondary)
                .foregroundStyle(.secondary)
                
                Picker("Time Range", selection: $selectedRange) {
                    Text("W").tag(GraphRanges.week)
                    Text("M").tag(GraphRanges.month)
                    Text("6M").tag(GraphRanges.sixMonths)
                    Text("Y").tag(GraphRanges.year)
                    Text("All").tag(GraphRanges.all)
                }
                .pickerStyle(.segmented)
                .padding(.top)
            }
            .padding()
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 12, style: .continuous))
            
            if filteredCalories.count > 1 {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Daily Average")
                            .foregroundStyle(.secondary)
                            .textScale(.secondary)
                        Text("\(averageCalories) Calories")
                            .font(.title2)
                    }
                    Spacer()
                    if previousFilteredCalories.count > 1 {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("Previous \(selectedRange.rawValue)")
                                .foregroundStyle(.secondary)
                                .textScale(.secondary)
                            Text("\(previousAverageCalories) Calories")
                                .font(.title2)
                        }
                    }
                }
                .fontWeight(.semibold)
                .padding()
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.horizontal)
        .navigationTitle("Calories Burned")
        .navigationBarTitleDisplayMode(.large)
        .vSpacing(.top)
    }
}
#Preview {
    NavigationView {
        CaloriesView()
    }
}
