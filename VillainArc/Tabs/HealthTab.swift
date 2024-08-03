import SwiftUI

enum HealthTabCategory: String, Identifiable, CaseIterable {
    case weight = "Weight"
    case steps = "Steps"
    case calories = "Calories"
    
    var systemImage: String {
        switch self {
        case .weight: "scalemass.fill"
        case .steps: "figure.walk"
        case .calories: "flame.fill"
        }
    }
    
    var id: String { self.rawValue }
}

struct HealthTab: View {
    @AppStorage("healthAccess") var healthAccess = false
    @Environment(\.modelContext) private var context
    @Binding var path: NavigationPath
    @State private var selection: HealthTabCategory = .weight
    @Namespace private var animation
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                BackgroundView()
                if healthAccess {
                    Group {
                        switch selection {
                        case .weight:
                            WeightView()
                        case .steps:
                            StepsView()
                        case .calories:
                            CaloriesView()
                        }
                    }
                    .onAppear {
                        Task {
                            await HealthManager.shared.fetchAndUpdateAllData(context: context)
                        }
                    }
                    
                    HStack(spacing: 30) {
                        ForEach(HealthTabCategory.allCases) { page in
                            Button {
                                withAnimation(.snappy) {
                                    selection = page
                                }
                            } label: {
                                Text(page.rawValue)
                                    .foregroundStyle(selection == page ? Color.primary : Color.secondary)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 6)
                                    .background {
                                        if selection == page {
                                            Capsule()
                                                .fill(.gray.opacity(0.3))
                                                .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
                                        }
                                    }
                            }
                        }
                    }
                    .padding(4)
                    .background(.ultraThickMaterial, in: .capsule)
                    .vSpacing(.bottom)
                    .padding([.bottom, .horizontal])
                    
                } else {
                    unavailableView
                }
            }
            .navigationDestination(for: Int.self) { int in
                if int == 0 {
                    WeightView()
                } else if int == 1 {
                    StepsView()
                } else if int == 2 {
                    CaloriesView()
                } else if int == 3 {
                    AllWeightEntriesView()
                }
            }
        }
    }
    
    var unavailableView: some View {
        ContentUnavailableView(label: {
            Label("Health Access", systemImage: "heart.text.square.fill")
        }, description: {
            Text("You haven't allowed access to health data.")
        }, actions: {
            Button {
                HealthManager.shared.requestHealthData { granted in
                    if granted {
                        HealthManager.shared.accessGranted { success in
                            if success {
                                healthAccess = true
                            }
                        }
                    }
                }
            } label:  {
                Text("Update Access")
                    .fontWeight(.semibold)
            }
        })
    }
}
