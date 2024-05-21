//
//  AllWeightEntriesView.swift
//  VillainArc
//
//  Created by Fernando Caudillo Tafoya on 5/20/24.
//

import SwiftUI
import SwiftData

struct AllWeightEntriesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    
    private func deleteWeightEntry(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let weightEntryToDelete = weightEntries[index]
                DataManager.shared.deleteWeightEntry(weightEntry: weightEntryToDelete, context: context)
            }
        }
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
            .navigationTitle("All Weight Entries")
    }
}

#Preview {
    AllWeightEntriesView()
}
