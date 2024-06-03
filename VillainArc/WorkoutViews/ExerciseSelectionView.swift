import SwiftUI

struct ExerciseSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedExercises: [Exercise] = []
    @State private var exercises: [Exercise] = loadExercises()
    
    var onAdd: ([Exercise]) -> Void
    
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
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises.sorted { $0.name < $1.name }
        } else {
            return exercises.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                VStack {
                    CustomSearchBar(searchText: $searchText)
                    List(filteredExercises) { exercise in
                        Button(action: {
                            if let index = selectedExercises.firstIndex(where: { $0.id == exercise.id }) {
                                selectedExercises.remove(at: index)
                            } else {
                                selectedExercises.append(exercise)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(exercise.name)
                                        .foregroundStyle(Color.primary)
                                        .font(.title3)
                                    Text(exercise.category)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.secondary)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .listRowBackground(selectedExercises.contains(where: { $0.id == exercise.id }) ? Color.blue.opacity(0.2) : Color.clear)
                    }
                    //.searchable(text: $searchText)
                    .listStyle(.plain)
                }
                .navigationTitle("Exercises")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            dismiss()
                        }, label: {
                            Text("Cancel")
                                .fontWeight(.semibold)
                                .foregroundStyle(.red)
                        })
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            onAdd(selectedExercises)
                            dismiss()
                        }, label: {
                            Text("Add (\(selectedExercises.count))")
                                .fontWeight(.semibold)
                        })
                        .disabled(selectedExercises.count == 0)
                    }
                }
            }
        }
    }
}
import SwiftUI

struct CustomSearchBar: View {
    @Binding var searchText: String
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            TextField("Search...", text: $searchText)
                .autocorrectionDisabled()
                .padding(7)
                .padding(.horizontal, 25)
                .background(BlurView())
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if isEditing {
                            Button(action: {
                                withAnimation {
                                    self.searchText = ""
                                }
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .padding(.horizontal, 10)
                .onTapGesture {
                    withAnimation {
                        self.isEditing = true
                    }
                }
            
            if isEditing {
                Button(action: {
                    withAnimation {
                        self.isEditing = false
                        self.searchText = ""
                        hideKeyboard()
                    }
                }) {
                    Text("Cancel")
                        .foregroundStyle(Color.primary)
                }
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
            }
        }
    }
}

#Preview {
    ExerciseSelectionView(onAdd: { _ in })
}
