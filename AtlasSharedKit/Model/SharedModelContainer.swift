//
//  SharedModelContainer.swift
//  AtlasMe
//
//  A shared factory extension that initializes and configures the SwiftData
//  ModelContainer with a persistent schema for use across both App and Widget targets.
//  The app mirrors the store to iCloud via CloudKit, while the widget only reads
//  the shared local store from the App Group container.
//

import SwiftData

public extension ModelContainer {
    static let cloudKitContainerIdentifier = "iCloud.net.yellowlake.AtlasMe"

    /// A shared factory method to initialize the SwiftData ModelContainer for both App and Widget targets.
    /// - Parameter syncWithCloudKit: Whether the store should be mirrored to iCloud. Only the main app
    ///   should enable this; extensions read the same local store that the app keeps in sync.
    static func createShared(syncWithCloudKit: Bool = false) -> ModelContainer {
        let schema = Schema([
            VisitedCountry.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: syncWithCloudKit ? .private(cloudKitContainerIdentifier) : .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
