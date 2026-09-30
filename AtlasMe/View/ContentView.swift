//
//  ContentView.swift
//  AtlasMe
//
//  The main container view of the app. It provides a tab bar interface to navigate
//  between the statistics home view, the list view of visited countries and
//  the interactive travel map.
//

import AtlasSharedKit
import SwiftData
import SwiftUI

struct ContentView: View {
    @Query private var visitedCountries: [VisitedCountry]
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "chart.bar.horizontal.page")
                }
                .tag(0)

            TravelListView()
                .tabItem {
                    Label("Countries", systemImage: "airplane.circle.fill")
                }
                .tag(1)

            TravelMapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(2)
        }
        .tint(.accent)
        .onAppear {
            // Send first-time users without any countries to the list view,
            // where they can add their first country
            if visitedCountries.isEmpty {
                selectedTab = 1
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = (try? ModelContainer(for: VisitedCountry.self, configurations: config)) ?? {
        fatalError("Failed to create preview container")
    }()

    // Seed some mock data for preview
    let sample = VisitedCountry(
        alpha2: "FR",
        dateVisited: Date(),
        notes: "Visited Paris, saw the Eiffel Tower!"
    )
    container.mainContext.insert(sample)

    return ContentView()
        .modelContainer(container)
}
