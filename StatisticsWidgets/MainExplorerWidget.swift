//
//  MainExplorerWidget.swift
//  AtlasMe
//
//  A timeline provider, entry model, and configuration view that define
//  the MainExplorerWidget, fetching current travel stats from SwiftData to
//  display world exploration progress.
//

import AtlasSharedKit
import SwiftData
import SwiftUI
import WidgetKit

private let sharedModelContainer: ModelContainer = .createShared()

struct MainExplorerEntry: TimelineEntry {
    let date: Date
    let visitedCount: Int
    let totalOfficial: Int
}

struct MainExplorerProvider: TimelineProvider {
    func placeholder(in _: Context) -> MainExplorerEntry {
        MainExplorerEntry(date: Date(), visitedCount: 0, totalOfficial: Country.allCountries.count)
    }

    func getSnapshot(in _: Context, completion: @escaping (MainExplorerEntry) -> Void) {
        Task { @MainActor in
            let entry = fetchEntry()
            completion(entry)
        }
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<MainExplorerEntry>) -> Void) {
        Task { @MainActor in
            let entry = fetchEntry()
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
        }
    }

    @MainActor
    private func fetchEntry() -> MainExplorerEntry {
        let container = sharedModelContainer
        let descriptor = FetchDescriptor<VisitedCountry>()
        let visitedCountries = (try? container.mainContext.fetch(descriptor)) ?? []
        let stats = StatisticsCalculations(visitedCountries: visitedCountries)
        return MainExplorerEntry(
            date: Date(),
            visitedCount: stats.visitedCount,
            totalOfficial: stats.totalOfficial
        )
    }
}

struct MainExplorerWidgetView: View {
    var entry: MainExplorerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MainExplorerCardContent(
                visitedCount: entry.visitedCount,
                totalOfficial: entry.totalOfficial
            )
        }
        .foregroundColor(.white)
        .padding(20)
    }
}

struct MainExplorerWidget: Widget {
    let kind: String = "MainExplorerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MainExplorerProvider()) { entry in
            MainExplorerWidgetView(entry: entry)
                .containerBackground(LinearGradient(
                    colors: [Color.accent, Color("AccentSecondColor")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), for: .widget)
        }
        .configurationDisplayName("World Explorer")
        .description("Track your world exploration progress.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemMedium) {
    MainExplorerWidget()
} timeline: {
    MainExplorerEntry(date: .now, visitedCount: 5, totalOfficial: 249)
    MainExplorerEntry(date: .now, visitedCount: 12, totalOfficial: 249)
}
