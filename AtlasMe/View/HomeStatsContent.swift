//
//  HomeStatsContent.swift
//  AtlasMe
//
//  The travel statistics shown on the home view, extracted into its own view so
//  the same content can be rendered into an image for sharing.
//

import AtlasSharedKit
import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

struct HomeStatsContent: View {
    let visitedCountries: [VisitedCountry]

    var body: some View {
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

                // Non-lazy grid, so the content also renders with ImageRenderer
                Grid(horizontalSpacing: 16, verticalSpacing: 16) {
                    GridRow {
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
                    }

                    GridRow {
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
        }
    }
}

/// Self-contained version of the home statistics, including a title and background,
/// used to render the shareable image.
struct HomeStatsShareCard: View {
    let visitedCountries: [VisitedCountry]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("My Atlas & Me")
                .font(.largeTitle)
                .fontWeight(.bold)

            HomeStatsContent(visitedCountries: visitedCountries)
        }
        .padding(24)
        .frame(width: 420)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
}

/// Rendered PNG of the share card. Shared as PNG data, so the exact rendered pixels
/// (including the transparent rounded corners) are passed on unchanged.
struct ShareableImage: Transferable {
    let pngData: Data
    let preview: Image

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { $0.pngData }
            .suggestedFileName("My Atlas & Me.png")
    }
}
