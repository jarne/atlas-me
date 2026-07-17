//
//  SharedModelContainer.swift
//  AtlasMe
//
//  A shared factory extension that initializes and configures the SwiftData
//  ModelContainer with a persistent schema for use across both App and Widget targets.
//

import SwiftData

public extension ModelContainer {
    /// A shared factory method to initialize the SwiftData ModelContainer for both App and Widget targets.
    static func createShared() -> ModelContainer {
        let schema = Schema([
            VisitedCountry.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
