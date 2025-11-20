import Foundation

enum Tabs: String {
    case workout = "Workout"
    
    var iconString: String {
        switch self {
        case .workout: "figure.strengthtraining.traditional"
        }
    }
}
