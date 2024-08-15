import SwiftUI
import SwiftData

struct AllWeightEntriesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @State private var isEditing = false
    @State private var showDeleteAllAlert = false
    @Namespace private var animation
    
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
            isEditing.toggle()
        }
    }
    
    var body: some View {
        List {
            ForEach(weightEntries, id: \.self) { weightEntry in
                HStack {
                    Text("\(formattedDouble(weightEntry.weight)) lbs")
                        .fontWeight(.semibold)
                    Spacer()
                    if weightEntry.photoData != nil {
                        Image(systemName: "photo")
                            .foregroundStyle(Color.secondary)
                            .font(.footnote)
                    }
                    if !weightEntry.notes.isEmpty {
                        Image(systemName: "doc.plaintext")
                            .foregroundStyle(Color.secondary)
                            .font(.footnote)
                    }
                    VStack(alignment: .trailing) {
                        Text("\(weightEntry.date.formatted(.dateTime.day().month().year()))")
                        Text("\(weightEntry.date.formatted(.dateTime.hour().minute()))")
                    }
                    .foregroundStyle(Color.secondary)
                    .font(.footnote)
                }
                .listRowBackground(BlurView())
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: deleteWeightEntry)
        }
        .scrollContentBackground(.hidden)
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
                    Button {
                        showDeleteAllAlert = true
                    } label: {
                        Text("Delete All")
                            .fontWeight(.semibold)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 9)
                            .background(Color.red, in: .rect(cornerRadius: 30, style: .continuous))
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if !weightEntries.isEmpty {
                    Button {
                        withAnimation {
                            isEditing.toggle()
                        }
                    } label: {
                        Text(isEditing ? "Done" : "Edit")
                            .fontWeight(.semibold)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 9)
                            .background(.ultraThinMaterial, in: .rect(cornerRadius: 30, style: .continuous))
                            .matchedGeometryEffect(id: "EDITMODE", in: animation)
                    }
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
        .background(BackgroundView())
    }
}

#Preview {
    NavigationView {
        AllWeightEntriesView()
    }
}
