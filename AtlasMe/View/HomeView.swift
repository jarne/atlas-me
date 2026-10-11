//
//  HomeView.swift
//  AtlasMe
//
//  Displays travel stats and exploration progress card.
//

import AtlasSharedKit
import SwiftData
import SwiftUI

struct HomeView: View {
    @Query private var visitedCountries: [VisitedCountry]
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale

    /// Renders the home statistics into a PNG image that can be shared
    private var shareImage: ShareableImage? {
        let renderer = ImageRenderer(
            content: HomeStatsShareCard(visitedCountries: visitedCountries)
                .environment(\.colorScheme, colorScheme)
        )
        renderer.scale = displayScale
        guard let uiImage = renderer.uiImage, let pngData = uiImage.pngData() else { return nil }
        return ShareableImage(pngData: pngData, preview: Image(uiImage: uiImage))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                HomeStatsContent(visitedCountries: visitedCountries)
                    .padding()
            }
            .navigationTitle("Atlas & Me")
            .toolbar {
                if let shareImage {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ShareLink(
                            item: shareImage,
                            preview: SharePreview("My Atlas & Me", image: shareImage.preview)
                        )
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CreditsView()) {
                        Image(systemName: "info.circle")
                    }
                }
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

    return HomeView()
        .modelContainer(container)
        .padding()
}
