import ActivityKit
import WidgetKit
import SwiftUI

struct WorkoutLiveActivityLiveActivity: Widget {
    func formattedWeight(_ weight: Double) -> String {
        let weightInt = Int(weight)
        return weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(weightInt)" : String(format: "%.1f", weight)
    }
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutAttributes.self) { context in
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(context.state.workoutTitle)
                            .fontWeight(.semibold)
                        HStack(spacing: 0) {
                            Text("Total Time: ")
                            Text(context.state.date, style: .timer)
                        }
                        .textScale(.secondary)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let endDate = context.state.endDate, Date() < endDate {
                        VStack(alignment: .center) {
                            Text("Rest Time")
                                .textScale(.secondary)
                                .foregroundStyle(.secondary)
                            Text(endDate, style: .timer)
                                .fontWeight(.semibold)
                                .frame(width: 40)
                        }
                    }
                }
                .padding(.bottom)
                if context.state.isEmpty {
                    Text("No Exercises Added")
                        .fontWeight(.semibold)
                } else {
                    if !context.state.exerciseName.isEmpty {
                        Text(context.state.exerciseName)
                            .fontWeight(.semibold)
                        HStack {
                            Text("Set: \(context.state.setNumber)")
                            Spacer()
                            Text("Reps: \(context.state.setReps)")
                            Spacer()
                            Text("Weight: \(formattedWeight(context.state.setWeight)) lbs")
                        }
                        .foregroundStyle(.secondary)
                    } else {
                        Text("All Exercises Done")
                            .fontWeight(.semibold)
                    }
                }
            }
            .foregroundStyle(.white)
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.5))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {}
                DynamicIslandExpandedRegion(.trailing) {}
                DynamicIslandExpandedRegion(.bottom) {}
            } compactLeading: {} compactTrailing: {} minimal: {}
        }
    }
}
