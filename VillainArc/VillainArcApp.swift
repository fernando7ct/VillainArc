//
//  VillainArcApp.swift
//  VillainArc
//
//  Created by Fernando Caudillo Tafoya on 5/15/24.
//

import SwiftUI
import SwiftData
import Firebase

@main
struct VillainArcApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WeightEntry.self, User.self])
    }
}
