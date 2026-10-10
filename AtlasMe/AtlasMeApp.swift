//
//  AtlasMeApp.swift
//  AtlasMe
//
//  This is the main entry point of the AtlasMe application. It initializes
//  the SwiftData model container for storing visited countries, handles iCloud sync changes
//  and bootstraps the user interface.
//

import AtlasSharedKit
import Combine
import CoreData
import SwiftData
import SwiftUI
import WidgetKit

@main
struct AtlasMeApp: App {
    var sharedModelContainer: ModelContainer = .createShared(syncWithCloudKit: true)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    VisitedCountry.deduplicate(in: sharedModelContainer.mainContext)
                }
                .onReceive(
                    NotificationCenter.default
                        .publisher(for: .NSPersistentStoreRemoteChange)
                        .debounce(for: .seconds(1), scheduler: RunLoop.main)
                ) { _ in
                    // Changes may have arrived from iCloud: merge added countries and
                    // refresh the widgets with the new data
                    VisitedCountry.deduplicate(in: sharedModelContainer.mainContext)
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
