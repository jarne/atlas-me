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

    private var velocityString: String {
        guard !visitedCountries.isEmpty else { return "0.0" }
        let dates = visitedCountries.map { $0.dateVisited }
        guard let minDate = dates.min() else { return "0.0" }
        let yearsElapsed = max(Date().timeIntervalSince(minDate) / (365.25 * 24 * 3600), 1.0)
        return String(format: "%.1f", Double(visitedCountries.count) / yearsElapsed)
    }

    private var vintageYearInfo: (year: String, subtitle: String) {
        guard !visitedCountries.isEmpty else {
            return (String(localized: "N/A"), String(localized: "No travels recorded"))
        }
        var yearCounts: [Int: Int] = [:]
        let calendar = Calendar.current
        for country in visitedCountries {
            let year = calendar.component(.year, from: country.dateVisited)
            yearCounts[year, default: 0] += 1
        }
        if let (mostActiveYear, maxVisits) = yearCounts.max(by: { $0.value < $1.value }) {
            let subtitle = maxVisits == 1
                ? String(localized: "1 country visited")
                : String(localized: "\(maxVisits) countries visited")
            return ("\(mostActiveYear)", subtitle)
        }
        return (String(localized: "N/A"), String(localized: "No travels recorded"))
    }

    private var pioneerString: String {
        if let pioneer = visitedCountries.min(by: { $0.dateVisited < $1.dateVisited }) {
            return "\(pioneer.flagEmoji) \(pioneer.name)"
        }
        return String(localized: "N/A")
    }

    private var latestAdditionString: String {
        if let latest = visitedCountries.max(by: { $0.dateVisited < $1.dateVisited }) {
            return "\(latest.flagEmoji) \(latest.name)"
        }
        return String(localized: "N/A")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    let totalOfficial = Country.allCountries.count
                    let visitedCount = visitedCountries.count

                    MainExplorerCard(visitedCount: visitedCount, totalOfficial: totalOfficial)

                    // Detailed Breakdown Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Countries Breakdown")
                            .font(.title3)
                            .fontWeight(.bold)

                        HStack(spacing: 16) {
                            StatMiniCard(
                                title: String(localized: "Total Visits"),
                                value: "\(visitedCount)",
                                icon: "airplane",
                                color: .blue
                            )

                            StatMiniCard(
                                title: String(localized: "Remaining"),
                                value: "\(max(0, totalOfficial - visitedCount))",
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
                                value: velocityString,
                                subtitle: String(localized: "New countries / year"),
                                icon: "speedometer",
                                color: .purple
                            )

                            let vintage = vintageYearInfo
                            InsightCard(
                                title: String(localized: "Explorer Year"),
                                value: vintage.year,
                                subtitle: vintage.subtitle,
                                icon: "calendar.badge.clock",
                                color: .green
                            )

                            InsightCard(
                                title: String(localized: "The Pioneer"),
                                value: pioneerString,
                                subtitle: String(localized: "First country visited"),
                                icon: "flag.fill",
                                color: .red
                            )

                            InsightCard(
                                title: String(localized: "Latest Addition"),
                                value: latestAdditionString,
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
