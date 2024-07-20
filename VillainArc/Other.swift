import SwiftUI

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
func formattedDouble(_ weight: Double) -> String {
    let weightInt = Int(weight)
    return weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(weightInt)" : String(format: "%.1f", weight)
}
func exerciseCategories(for workout: Workout) -> String {
    let exercises = workout.exercises
    let categories = Set(exercises.map { $0.category })
    return categories.joined(separator: ", ")
}
func topSet(for exerciseInfo: ExerciseInfo) -> String {
    guard let topSet = exerciseInfo.sets.max(by: {
        if $0.weight == $1.weight {
            return $0.reps < $1.reps
        } else {
            return $0.weight < $1.weight
        }
    }) else {
        return "No sets"
    }
    return "Top Set: \(topSet.reps)x\(formattedDouble(topSet.weight)) lbs"
}
func totalWorkoutTime(startTime: Date, endTime: Date) -> String {
    let timeInterval = endTime.timeIntervalSince(startTime)
    let hours = Int(timeInterval) / 3600
    let minutes = (Int(timeInterval) % 3600) / 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}
func formattedTotalTime(_ timeInterval: TimeInterval) -> String {
    let secondsInYear: Double = 60 * 60 * 24 * 365
    let secondsInMonth: Double = 60 * 60 * 24 * 30
    let secondsInDay: Double = 60 * 60 * 24
    let secondsInHour: Double = 60 * 60
    let secondsInMinute: Double = 60

    if timeInterval >= secondsInYear {
        return String(format: "%.1f years", timeInterval / secondsInYear)
    } else if timeInterval >= secondsInMonth {
        return String(format: "%.1f months", timeInterval / secondsInMonth)
    } else if timeInterval >= secondsInDay {
        return String(format: "%.1f days", timeInterval / secondsInDay)
    } else if timeInterval >= secondsInHour {
        return String(format: "%.1f hrs", timeInterval / secondsInHour)
    } else if timeInterval >= secondsInMinute {
        return String(format: "%.1f mins", timeInterval / secondsInMinute)
    } else {
        return String(format: "%.1f secs", timeInterval)
    }
}
func xAxisRange(startDate: Date, selectedRange: GraphRanges) -> ClosedRange<Date> {
    let calendar = Calendar.current
    let endDate: Date
    switch selectedRange {
    case .week:
        endDate = calendar.date(byAdding: .day, value: 7, to: startDate)!
    case .month:
        endDate = calendar.date(byAdding: .month, value: 1, to: startDate)!
    case .sixMonths:
        endDate = calendar.date(byAdding: .month, value: 6, to: startDate)!
    }
    return startDate...endDate
}
func adjustDate(_ date: Date, selectedRange: GraphRanges) -> Date {
    let calendar = Calendar.current
    if selectedRange == .sixMonths {
        return calendar.date(byAdding: .day, value: 15, to: date)!
    } else {
        return calendar.date(byAdding: .hour, value: 12, to: date)!
    }
}
func dateRange(startDate: Date, selectedRange: GraphRanges) -> String {
    let calendar = Calendar.current
    switch selectedRange {
    case .week:
        let endDate = calendar.date(byAdding: .day, value: 6, to: startDate)!
        return "\(startDate.formatted(.dateTime.month().day())) - \(endDate.formatted(.dateTime.month().day()))"
    case .month:
        return "\(startDate.formatted(.dateTime.month(.wide).year()))"
    case .sixMonths:
        let endDate = calendar.date(byAdding: .month, value: 5, to: startDate)!
        return "\(startDate.formatted(.dateTime.month(.wide).year())) - \(endDate.formatted(.dateTime.month(.wide).year()))"
    }
}
func annotationDate(for date: Date, selectedRange: GraphRanges) -> String {
    if selectedRange == .sixMonths {
        return "\(date.formatted(.dateTime.month().year()))"
    } else {
        return "\(date.formatted(.dateTime.month().day().year()))"
    }
}
