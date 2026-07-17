//
//  AtlasMeApp.swift
//  AtlasMe
//
//  This is the main entry point of the AtlasMe application. It initializes
//  the SwiftData model container for storing visited countries and bootstraps the user interface.
//

import AtlasSharedKit
import SwiftData
import SwiftUI

@main
struct AtlasMeApp: App {
    var sharedModelContainer: ModelContainer = .createShared()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
