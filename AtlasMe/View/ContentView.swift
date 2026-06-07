//
//  ContentView.swift
//  AtlasMe
//
//  The main container view of the app. It provides a tab bar interface to navigate
//  between the list view of visited countries and the interactive travel map.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TravelListView()
                .tabItem {
                    Label("Travels", systemImage: "airplane.circle.fill")
                }
                .tag(0)
            
            TravelMapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(1)
        }
        .tint(.blue)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: VisitedCountry.self, configurations: config)
    
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
