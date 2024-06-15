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
                Text(context.attributes.workoutTitle)
                    .fontWeight(.semibold)
                HStack(spacing: 0) {
                    Text("Total Time: ")
                    Text(context.state.date, style: .timer)
                }
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .padding(.bottom)
                if context.state.isEmpty {
                    Text("No Exercises Added")
                        .fontWeight(.semibold)
                } else {
                    if !context.state.exerciesName.isEmpty {
                        Text(context.state.exerciesName)
                            .fontWeight(.semibold)
                        HStack {
                            Text("Set: \(context.state.setNumber)")
                            Spacer()
                            Text("Reps: \(context.state.setReps)")
                            Spacer()
                            Text("Weight: \(formattedWeight(context.state.setWeight)) lbs")
                        }
                        .foregroundStyle(Color.secondary)
                    } else {
                        Text("All Exercises Done")
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    
                }
                DynamicIslandExpandedRegion(.trailing) {
                }
                DynamicIslandExpandedRegion(.bottom) {
                }
            } compactLeading: {
            
            } compactTrailing: {
            } minimal: {
            }
        }
    }
}
