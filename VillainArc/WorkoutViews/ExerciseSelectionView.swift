import SwiftUI

struct ExerciseSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedExercises: [Exercise] = []
    @State private var exercises: [Exercise] = loadExercises()
    @Binding var exerciseToReplaceIndex: Int?
    var onAdd: ([Exercise]) -> Void
    var onReplace: (Int, Exercise) -> Void
    
    struct Exercise: Identifiable, Codable {
        var id = UUID()
        let name: String
        let category: String
        
        enum CodingKeys: String, CodingKey {
            case name, category
        }
        
        init(id: UUID = UUID(), name: String, category: String) {
            self.id = id
            self.name = name
            self.category = category
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = UUID()
            self.name = try container.decode(String.self, forKey: .name)
            self.category = try container.decode(String.self, forKey: .category)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(category, forKey: .category)
        }
    }
    
    private static func loadExercises() -> [Exercise] {
        if let url = Bundle.main.url(forResource: "exercises", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let exercises = try JSONDecoder().decode([Exercise].self, from: data)
                return exercises
            } catch {
                print("Failed to load data or decode JSON: \(error)")
            }
        }
        return []
    }
    
    private func tokenize(_ text: String) -> [String] {
        return text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    }
    
    private func fuzzyMatch(_ text: String, with searchTokens: [String]) -> Bool {
        let tokens = tokenize(text)
        for searchToken in searchTokens {
            if !tokens.contains(where: { $0.contains(searchToken) || levenshteinDistance($0, searchToken) <= 2 }) {
                return false
            }
        }
        return true
    }
    
    private func levenshteinDistance(_ lhs: String, _ rhs: String) -> Int {
        let lhsCount = lhs.count
        let rhsCount = rhs.count
        var matrix = Array(repeating: Array(repeating: 0, count: rhsCount + 1), count: lhsCount + 1)
        
        for i in 0...lhsCount { matrix[i][0] = i }
        for j in 0...rhsCount { matrix[0][j] = j }
        
        for i in 1...lhsCount {
            for j in 1...rhsCount {
                if lhs[lhs.index(lhs.startIndex, offsetBy: i - 1)] == rhs[rhs.index(rhs.startIndex, offsetBy: j - 1)] {
                    matrix[i][j] = matrix[i - 1][j - 1]
                } else {
                    matrix[i][j] = min(
                        matrix[i - 1][j] + 1,
                        matrix[i][j - 1] + 1,
                        matrix[i - 1][j - 1] + 1
                    )
                }
            }
        }
        return matrix[lhsCount][rhsCount]
    }
    
    var filteredExercises: [Exercise] {
        let searchTokens = tokenize(searchText)
        
        if searchTokens.isEmpty {
            return exercises.sorted { $0.name < $1.name }
        } else {
            return exercises.filter { exercise in
                fuzzyMatch(exercise.name, with: searchTokens) || fuzzyMatch(exercise.category, with: searchTokens)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List(filteredExercises) { exercise in
                Button {
                    if let index = exerciseToReplaceIndex {
                        onReplace(index, exercise)
                        dismiss()
                    } else {
                        if let index = selectedExercises.firstIndex(where: { $0.id == exercise.id }) {
                            selectedExercises.remove(at: index)
                        } else {
                            selectedExercises.append(exercise)
                        }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .foregroundStyle(.primary)
                                .font(.title3)
                            Text(exercise.category)
                                .textScale(.secondary)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .hSpacing(.leading)
                }
                .buttonStyle(BorderlessButtonStyle())
                .listRowBackground(selectedExercises.contains(where: { $0.id == exercise.id }) ? Color.blue.opacity(0.2) : Color.clear)
            }
            .searchable(text: $searchText)
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .listStyle(.plain)
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                        if exerciseToReplaceIndex != nil {
                            exerciseToReplaceIndex = nil
                        }
                    } label: {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                    }
                }
                if exerciseToReplaceIndex == nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            onAdd(selectedExercises)
                            dismiss()
                        } label: {
                            Text("Add (\(selectedExercises.count))")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .background(BackgroundView())
        }
    }
}

#Preview {
    ExerciseSelectionView(exerciseToReplaceIndex: .constant(nil), onAdd: { _ in }, onReplace: { _, _ in })
        .tint(.primary)
}
