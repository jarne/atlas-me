//
//  VisitedCountryDeduplication.swift
//  AtlasMe
//
//  Merges duplicate VisitedCountry entries for the same country. Since CloudKit
//  doesn't support unique constraints, the same country can end up stored twice
//  when it is added on multiple devices before they have synced with each other.
//

import Foundation
import SwiftData

public extension VisitedCountry {
    /// Merges all entries sharing the same country code into a single one, keeping the
    /// earliest visit date and combining their notes.
    /// - Returns: Whether any duplicates were found and merged.
    @discardableResult
    static func deduplicate(in modelContext: ModelContext) -> Bool {
        guard let allVisited = try? modelContext.fetch(FetchDescriptor<VisitedCountry>()) else {
            return false
        }

        var didMerge = false
        for (_, entries) in Dictionary(grouping: allVisited, by: { $0.alpha2.uppercased() }) where entries.count > 1 {
            // Sort deterministically so that every device picks the same entry to keep
            let sorted = entries.sorted {
                ($0.dateVisited, $0.notes) < ($1.dateVisited, $1.notes)
            }
            let kept = sorted[0]

            var mergedNotes: [String] = []
            for entry in sorted where !entry.notes.isEmpty && !mergedNotes.contains(entry.notes) {
                mergedNotes.append(entry.notes)
            }
            let notes = mergedNotes.joined(separator: "\n\n")
            if kept.notes != notes {
                kept.notes = notes
            }

            for duplicate in sorted.dropFirst() {
                modelContext.delete(duplicate)
            }
            didMerge = true
        }

        if didMerge {
            try? modelContext.save()
        }
        return didMerge
    }
}
