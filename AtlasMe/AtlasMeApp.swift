//
//  AtlasMeApp.swift
//  AtlasMe
//
//  This is the main entry point of the AtlasMe application. It initializes
//  the SwiftData model container for storing visited countries and bootstraps the user interface.
//

import SwiftUI
import SwiftData

@main
struct AtlasMeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            VisitedCountry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
