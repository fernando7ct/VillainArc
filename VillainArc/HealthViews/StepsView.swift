import SwiftUI
import Charts
import SwiftData

struct StepsView: View {
    @Query(sort: \HealthSteps.date, order: .reverse) private var healthSteps: [HealthSteps]
    @State private var selectedRange: GraphRanges = .month
    @State private var selectedDate: Date? = nil
    @State private var selectedEntry: HealthSteps? = nil
    
    private func yAxisRange() -> ClosedRange<Double> {
        guard let maxSteps = filteredSteps.map({ $0.steps }).max() else {
            return 0...10000
        }
        return 0...(maxSteps + 2000)
    }
    
    private func xAxisRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let endDate = Date.now.startOfDay
        let startDate: Date
        
        if healthSteps.isEmpty {
            startDate = endDate.startOfDay
        } else {
            let oldestEntryDate = healthSteps.map { $0.date }.min()!
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
    
    var filteredSteps: [HealthSteps] {
        let calendar = Calendar.current
        switch selectedRange {
        case .week:
            let startDate = calendar.date(byAdding: .day, value: -7, to: .now.startOfDay)!
            return healthSteps.filter({ $0.date >= startDate})
        case .month:
            let startDate = calendar.date(byAdding: .month, value: -1, to: .now.startOfDay)!
            return healthSteps.filter({ $0.date >= startDate})
        case .sixMonths:
            let startDate = calendar.date(byAdding: .month, value: -6, to: .now.startOfDay)!
            return healthSteps.filter({ $0.date >= startDate})
        case .year:
            let startDate = calendar.date(byAdding: .year, value: -1, to: .now.startOfDay)!
            return healthSteps.filter({ $0.date >= startDate})
        case .all:
            return healthSteps
        }
    }
    var previousFilteredSteps: [HealthSteps] {
        let calendar = Calendar.current
        switch selectedRange {
        case .week:
            let originalStartDate = calendar.date(byAdding: .day, value: -7, to: .now.startOfDay)!
            let newStartDate = calendar.date(byAdding: .day, value: -7, to: originalStartDate)!
            return healthSteps.filter({ $0.date < originalStartDate && $0.date >= newStartDate })
        case .month:
            let originalStartDate = calendar.date(byAdding: .month, value: -1, to: .now.startOfDay)!
            let newStartDate = calendar.date(byAdding: .month, value: -1, to: originalStartDate)!
            return healthSteps.filter({ $0.date < originalStartDate && $0.date >= newStartDate })
        case .sixMonths:
            let originalStartDate = calendar.date(byAdding: .month, value: -6, to: .now.startOfDay)!
            let newStartDate = calendar.date(byAdding: .month, value: -6, to: originalStartDate)!
            return healthSteps.filter({ $0.date < originalStartDate && $0.date >= newStartDate })
        case .year:
            let originalStartDate = calendar.date(byAdding: .year, value: -1, to: .now.startOfDay)!
            let newStartDate = calendar.date(byAdding: .year, value: -1, to: originalStartDate)!
            return healthSteps.filter({ $0.date < originalStartDate && $0.date >= newStartDate })
        case .all:
            return []
        }
    }
    var averageSteps: Int {
        guard !healthSteps.isEmpty else { return 0 }
        return Int(filteredSteps.reduce(0) { $0 + $1.steps } / Double(filteredSteps.count))
    }
    var previousAverageSteps: Int {
        guard !healthSteps.isEmpty else { return 0 }
        return Int(previousFilteredSteps.reduce(0) { $0 + $1.steps } / Double(previousFilteredSteps.count))
    }
    
    var body: some View {
        VStack {
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 0) {
                        if !healthSteps.isEmpty {
                            if let today = healthSteps.first(where: { $0.date == .now.startOfDay }) {
                                Text("Today")
                                    .foregroundStyle(.secondary)
                                    .textScale(.secondary)
                                Text("\(Int(today.steps)) Steps")
                                    .font(.title)
                            } else if let mostRecent = healthSteps.first {
                                Text(mostRecent.date, format: .dateTime.month().day().year())
                                    .foregroundStyle(.secondary)
                                    .textScale(.secondary)
                                Text("\(Int(mostRecent.steps)) Steps")
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
                
                Chart(filteredSteps) { day in
                    AreaMark(x: .value("Date", day.date), yStart: .value("Steps", 0), yEnd: .value("Steps", day.steps))
                        .foregroundStyle(Color.red.opacity(0.4))
                        .interpolationMethod(.monotone)
                    LineMark(x: .value("Date", day.date), y: .value("Steps", day.steps))
                        .foregroundStyle(Color.red)
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                    if let selectedEntry {
                        PointMark(x: .value("Date", selectedEntry.date), y: .value("Steps", selectedEntry.steps))
                            .foregroundStyle(Color.red)
                        RuleMark(x: .value("Date", selectedEntry.date))
                            .foregroundStyle(Color.red)
                            .lineStyle(StrokeStyle(lineWidth: 1.5))
                            .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("\(selectedEntry.date.formatted(.dateTime.month().day().year()))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    HStack(alignment: .bottom, spacing: 3) {
                                        Text("\(Int(selectedEntry.steps))")
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                        Text("Steps")
                                            .foregroundStyle(.secondary)
                                            .padding(.bottom, 1)
                                    }
                                }
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Color.red.gradient)
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
                        if let currentEntry = filteredSteps.first(where: { item in
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
                        .padding(.trailing, 45)
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
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            if filteredSteps.count > 1 {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Daily Average")
                            .foregroundStyle(.secondary)
                            .textScale(.secondary)
                        Text("\(averageSteps) Steps")
                            .font(.title2)
                    }
                    Spacer()
                    if previousFilteredSteps.count > 1 {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("Previous \(selectedRange.rawValue)")
                                .foregroundStyle(.secondary)
                                .textScale(.secondary)
                            Text("\(previousAverageSteps) Steps")
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
        .navigationTitle("Steps")
        .navigationBarTitleDisplayMode(.large)
        .vSpacing(.top)
    }
}

#Preview {
    NavigationView {
        StepsView()
    }
}
