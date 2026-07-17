//
//  TravelInsightsWidget.swift
//  AtlasMe
//
//  A timeline provider, entry model, and layout views that define the TravelInsightsWidget,
//  querying SwiftData to display detailed travel metrics—such as travel velocity, peak year,
//  and milestone countries—on a large Home Screen widget.
//

import AtlasSharedKit
import SwiftData
import SwiftUI
import WidgetKit

private let sharedModelContainer: ModelContainer = .createShared()

struct TravelInsightsEntry: TimelineEntry {
    let date: Date
    let velocityString: String
    let vintageYear: String
    let vintageSubtitle: String
    let pioneerString: String
    let latestAdditionString: String
}

struct TravelInsightsProvider: TimelineProvider {
    func placeholder(in _: Context) -> TravelInsightsEntry {
        TravelInsightsEntry(
            date: Date(),
            velocityString: "0.0",
            vintageYear: "N/A",
            vintageSubtitle: "No travels recorded",
            pioneerString: "N/A",
            latestAdditionString: "N/A"
        )
    }

    func getSnapshot(in _: Context, completion: @escaping (TravelInsightsEntry) -> Void) {
        Task { @MainActor in
            let entry = fetchEntry()
            completion(entry)
        }
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<TravelInsightsEntry>) -> Void) {
        Task { @MainActor in
            let entry = fetchEntry()
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
        }
    }

    @MainActor
    private func fetchEntry() -> TravelInsightsEntry {
        let container = sharedModelContainer
        let descriptor = FetchDescriptor<VisitedCountry>()
        let visitedCountries = (try? container.mainContext.fetch(descriptor)) ?? []
        let stats = StatisticsCalculations(visitedCountries: visitedCountries)
        let vintage = stats.vintageYearInfo
        return TravelInsightsEntry(
            date: Date(),
            velocityString: stats.velocityString,
            vintageYear: vintage.year,
            vintageSubtitle: vintage.subtitle,
            pioneerString: stats.pioneerString,
            latestAdditionString: stats.latestAdditionString
        )
    }
}

struct TravelInsightsWidgetView: View {
    var entry: TravelInsightsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Travel Insights")
                .font(.title3)
                .fontWeight(.bold)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                InsightCard(
                    title: String(localized: "Velocity"),
                    value: entry.velocityString,
                    subtitle: String(localized: "New countries / year"),
                    icon: "speedometer",
                    color: .purple
                )

                InsightCard(
                    title: String(localized: "Explorer Year"),
                    value: entry.vintageYear,
                    subtitle: entry.vintageSubtitle,
                    icon: "calendar.badge.clock",
                    color: .green
                )

                InsightCard(
                    title: String(localized: "The Pioneer"),
                    value: entry.pioneerString,
                    subtitle: String(localized: "First country visited"),
                    icon: "flag.fill",
                    color: .red
                )

                InsightCard(
                    title: String(localized: "Latest Addition"),
                    value: entry.latestAdditionString,
                    subtitle: String(localized: "Most recently visited"),
                    icon: "clock.fill",
                    color: .teal
                )
            }
        }
    }
}

struct TravelInsightsWidget: Widget {
    let kind: String = "TravelInsightsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TravelInsightsProvider()) { entry in
            TravelInsightsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Travel Insights")
        .description("View statistics and insights from your travels.")
        .supportedFamilies([.systemLarge])
    }
}

#Preview(as: .systemLarge) {
    TravelInsightsWidget()
} timeline: {
    TravelInsightsEntry(
        date: .now,
        velocityString: "3.5",
        vintageYear: "2024",
        vintageSubtitle: "4 countries visited",
        pioneerString: "🇫🇷 France",
        latestAdditionString: "🇯🇵 Japan"
    )
}
