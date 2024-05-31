import SwiftUI
import SwiftData

struct AllWeightEntriesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @State private var isEditing = false
    @State private var showDeleteAllAlert = false
    
    private func deleteWeightEntry(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let weightEntryToDelete = weightEntries[index]
                DataManager.shared.deleteWeightEntry(weightEntry: weightEntryToDelete, context: context)
            }
        }
    }
    
    private func deleteAllEntries() {
        withAnimation {
            for entry in weightEntries {
                DataManager.shared.deleteWeightEntry(weightEntry: entry, context: context)
            }
        }
        isEditing.toggle()
    }
    
    var body: some View {
        List {
            ForEach(weightEntries, id: \.self) { weightEntry in
                HStack {
                    Image(systemName: "scalemass.fill")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    Text("\(formattedWeight(weightEntry.weight)) lbs")
                        .fontWeight(.semibold)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(weightEntry.date.formatted(.dateTime.day().month().year()))")
                        Text("\(weightEntry.date.formatted(.dateTime.hour().minute()))")
                    }
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                }
            }
            .onDelete(perform: deleteWeightEntry)
        }
        .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
        .overlay {
            if weightEntries.isEmpty {
                ContentUnavailableView("You have no weight entries.", systemImage: "scalemass.fill")
            }
        }
        .navigationTitle("All Weight Entries")
        .navigationBarBackButtonHidden(isEditing && !weightEntries.isEmpty)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isEditing && !weightEntries.isEmpty {
                    Button(action: {
                        showDeleteAllAlert = true
                    }, label: {
                        Text("Delete All")
                            .foregroundColor(.red)
                    })
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if !weightEntries.isEmpty {
                    Button(action: {
                        isEditing.toggle()
                    }, label: {
                        Text(isEditing ? "Done" : "Edit")
                    })
                }
            }
        }
        .alert(isPresented: $showDeleteAllAlert) {
            Alert(
                title: Text("Delete All Entries"),
                message: Text("Are you sure you want to delete all weight entries?"),
                primaryButton: .destructive(Text("Delete All")) {
                    deleteAllEntries()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

#Preview {
    AllWeightEntriesView()
}
