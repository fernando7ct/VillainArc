import SwiftUI

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
func formattedDouble(_ double: Double) -> String {
    let doubleInt = Int(double)
    return double.truncatingRemainder(dividingBy: 1) == 0 ? "\(doubleInt)" : String(format: "%.1f", double)
}
func formattedDouble2(_ double: Double) -> String {
    let doubleInt = Int(double)
    return double.truncatingRemainder(dividingBy: 1) == 0 ? "\(doubleInt)" : String(format: "%.2f", double)
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
enum GraphRanges: String, Identifiable, CaseIterable {
    case week = "Week"
    case month = "Month"
    case sixMonths = "6 Months"
    case year = "Year"
    case all = "All"
    
    var id: String { self.rawValue }
}
