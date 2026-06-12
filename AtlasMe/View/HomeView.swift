//
//  HomeView.swift
//  AtlasMe
//
//  Displays travel stats and exploration progress card.
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @Query private var visitedCountries: [VisitedCountry]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    let totalOfficial = Country.allCountries.count
                    let visitedCount = visitedCountries.count
                    let percentage = totalOfficial > 0 ? (Double(visitedCount) / Double(totalOfficial)) * 100.0 : 0.0
                    var formattedPercentage: String {
                        (percentage / 100).formatted(.percent.precision(.fractionLength(1)))
                    }

                    // Main Explorer Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("WORLD EXPLORER")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white.opacity(0.8))
                                    .tracking(1.5)

                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text("\(visitedCount)")
                                        .font(.system(size: 40, weight: .bold, design: .rounded))
                                    Text("/ \(totalOfficial) Countries")
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }

                            Spacer()

                            // Globe badge
                            Image(systemName: "globe.europe.africa.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white.opacity(0.9))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("\(formattedPercentage) of the world visited")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Spacer()
                            }

                            ProgressView(value: percentage, total: 100.0)
                                .tint(.white)
                                .background(Color.white.opacity(0.4))
                                .clipShape(Capsule())
                        }
                    }
                    .foregroundColor(.white)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accent, Color("SecondaryColor")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                    )

                    // Detailed Breakdown Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Stats Breakdown")
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
                }
                .padding()
            }
            .navigationTitle("Overview")
        }
    }
}

struct StatMiniCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .padding(12)
                .background(color.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
