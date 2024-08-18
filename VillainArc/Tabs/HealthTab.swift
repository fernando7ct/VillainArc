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
    @AppStorage("healthTabSelection") var healthTabSelection: HealthTabCategory = .weight
    
    var body: some View {
        if healthAccess {
            NavigationStack(path: $path) {
                Group {
                    switch healthTabSelection {
                    case .weight: WeightView()
                    case .steps: StepsView()
                    case .calories: CaloriesView()
                    }
                }
                .background(BackgroundView())
                .overlay(alignment: .bottom) {
                    HStack(spacing: 30) {
                        ForEach(HealthTabCategory.allCases) { page in
                            Button {
                                healthTabSelection = page
                            } label: {
                                Text(page.rawValue)
                                    .foregroundStyle(healthTabSelection == page ? Color.primary : Color.secondary)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 6)
                                    .background {
                                        if healthTabSelection == page {
                                            Capsule()
                                                .fill(.gray.opacity(0.3))
                                        }
                                    }
                            }
                        }
                    }
                    .padding(4)
                    .background(.ultraThickMaterial, in: .capsule)
                    .padding(.bottom)
                }
                .navigationDestination(for: Int.self) { int in
                    if int == 0 {
                        AllWeightEntriesView()
                    }
                }
            }
        } else {
            ContentUnavailableView {
                Label("Health Access", systemImage: "heart.text.square.fill")
            } description: {
                Text("You haven't allowed access to health data.")
            } actions: {
                Button {
                    HealthManager.shared.requestHealthData { granted in
                        if granted {
                            HealthManager.shared.accessGranted(context: context) { success in
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
            }
            .background(BackgroundView())
        }
    }
}

#Preview {
    HealthTab(path: .constant(.init()))
}
