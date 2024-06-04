//
//  WorkoutWidgetsBundle.swift
//  WorkoutWidgets
//
//  Created by Fernando Caudillo Tafoya on 6/3/24.
//

import WidgetKit
import SwiftUI

@main
struct WorkoutWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WorkoutWidgets()
        WorkoutWidgetsLiveActivity()
        WorkoutLiveActivity()
    }
}
