import SwiftUI
import Charts
import SwiftData

struct WeightView: View {
    @State private var addWeightSheetActive = false
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @State private var selectedRange: GraphRanges = .month
    @State private var selectedDate: Date? = nil
    @State private var selectedEntry: WeightEntry? = nil
    
    private func yAxisRange() -> ClosedRange<Double> {
        guard let minWeight = filteredEntries.map({ $0.weight }).min(),
              let maxWeight = filteredEntries.map({ $0.weight }).max() else {
            return 0...100
        }
        return (minWeight < 5 ? 0 : minWeight - 5)...(maxWeight + 5)
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
    
    var filteredEntries: [WeightEntry] {
        let calendar = Calendar.current
        switch selectedRange {
        case .week:
            let startDate = calendar.date(byAdding: .day, value: -7, to: .now.startOfDay)!
            return weightEntries.filter({ $0.date >= startDate})
        case .month:
            let startDate = calendar.date(byAdding: .month, value: -1, to: .now.startOfDay)!
            return weightEntries.filter({ $0.date >= startDate})
        case .sixMonths:
            let startDate = calendar.date(byAdding: .month, value: -6, to: .now.startOfDay)!
            return weightEntries.filter({ $0.date >= startDate})
        case .year:
            let startDate = calendar.date(byAdding: .year, value: -1, to: .now.startOfDay)!
            return weightEntries.filter({ $0.date >= startDate})
        case .all:
            return weightEntries
        }
    }
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        if !weightEntries.isEmpty {
                            if let today = weightEntries.first(where: { $0.date.isSameDayAs(.now) }) {
                                Text("Today")
                                    .foregroundStyle(.secondary)
                                    .textScale(.secondary)
                                Text("\(formattedDouble(today.weight)) lbs")
                                    .font(.title)
                            } else if let mostRecent = weightEntries.first {
                                Text(mostRecent.date, format: .dateTime.month().day().year())
                                    .foregroundStyle(.secondary)
                                    .textScale(.secondary)
                                Text("\(formattedDouble(mostRecent.weight)) lbs")
                                    .font(.title)
                            }
                        } else {
                            Text("No Data")
                                .font(.title)
                        }
                    }
                    .fontWeight(.semibold)
                }
                .hSpacing(.leading)
                .padding(.bottom)
                
                Chart(filteredEntries) { weight in
                    AreaMark(x: .value("Date", weight.date), yStart: .value("Weight", yAxisRange().lowerBound), yEnd: .value("Weight", weight.weight))
                        .foregroundStyle(Color.blue.opacity(0.4))
                        .interpolationMethod(.monotone)
                    LineMark(x: .value("Date", weight.date), y: .value("Weight", weight.weight))
                        .foregroundStyle(Color.blue)
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                    if let selectedEntry {
                        PointMark(x: .value("Date", selectedEntry.date), y: .value("Weight", selectedEntry.weight))
                            .foregroundStyle(Color.blue)
                        RuleMark(x: .value("Date", selectedEntry.date))
                            .foregroundStyle(Color.blue)
                            .lineStyle(StrokeStyle(lineWidth: 1.5))
                            .annotation(position: .top, overflowResolution: .init(x: .fit(to: .plot), y: .fit(to: .chart))) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("\(selectedEntry.date.formatted(.dateTime.month().day().year()))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    HStack(alignment: .bottom, spacing: 3) {
                                        Text("\(formattedDouble(selectedEntry.weight))")
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
                                .background {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Color.blue.gradient)
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
                        if let currentEntry = filteredEntries.first(where: { item in
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
                        .padding(.trailing, 30)
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
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            
            NavigationLink(value: 3) {
                HStack {
                    Text("All Weight Entries")
                        .fontWeight(.semibold)
                }
                .hSpacing(.leading)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
        .padding(.horizontal)
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addWeightSheetActive = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.primary)
                }
                .sheet(isPresented: $addWeightSheetActive) {
                    AddWeightEntryView()
                }
            }
        }
        .vSpacing(.top)
    }
}

#Preview {
    NavigationView {
        WeightView()
    }
}
