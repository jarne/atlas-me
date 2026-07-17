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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    let statisticsCalculations = StatisticsCalculations(visitedCountries: visitedCountries)

                    MainExplorerCard(
                        visitedCount: statisticsCalculations.visitedCount,
                        totalOfficial: statisticsCalculations.totalOfficial
                    )

                    // Detailed Breakdown Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Countries Breakdown")
                            .font(.title3)
                            .fontWeight(.bold)

                        HStack(spacing: 16) {
                            StatMiniCard(
                                title: String(localized: "Total Visits"),
                                value: "\(statisticsCalculations.visitedCount)",
                                icon: "airplane",
                                color: .blue
                            )

                            StatMiniCard(
                                title: String(localized: "Remaining"),
                                value: "\(statisticsCalculations.remainingCount)",
                                icon: "map",
                                color: .orange
                            )
                        }
                    }

                    // Travel Insights Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Travel Insights")
                            .font(.title3)
                            .fontWeight(.bold)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            InsightCard(
                                title: String(localized: "Velocity"),
                                value: statisticsCalculations.velocityString,
                                subtitle: String(localized: "New countries / year"),
                                icon: "speedometer",
                                color: .purple
                            )

                            let vintage = statisticsCalculations.vintageYearInfo
                            InsightCard(
                                title: String(localized: "Explorer Year"),
                                value: vintage.year,
                                subtitle: vintage.subtitle,
                                icon: "calendar.badge.clock",
                                color: .green
                            )

                            InsightCard(
                                title: String(localized: "The Pioneer"),
                                value: statisticsCalculations.pioneerString,
                                subtitle: String(localized: "First country visited"),
                                icon: "flag.fill",
                                color: .red
                            )

                            InsightCard(
                                title: String(localized: "Latest Addition"),
                                value: statisticsCalculations.latestAdditionString,
                                subtitle: String(localized: "Most recently visited"),
                                icon: "clock.fill",
                                color: .teal
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Atlas & Me")
            .toolbar {
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
