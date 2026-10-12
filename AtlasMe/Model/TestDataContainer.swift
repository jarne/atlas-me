//
//  TestDataContainer.swift
//  AtlasMe
//
//  Provides an in-memory SwiftData ModelContainer seeded with a fixed set of
//  visited countries. It is used when the app is launched with the
//  UseTestData argument (e.g. for UI tests and marketing screenshots).
//  Actual stored data is never changed.
//

import AtlasSharedKit
import Foundation
import SwiftData

extension ModelContainer {
    static let useTestDataLaunchArgument = "-UseTestData"
    static var shouldUseTestData: Bool {
        ProcessInfo.processInfo.arguments.contains(useTestDataLaunchArgument)
    }

    /// Creates an in-memory ModelContainer seeded with a fixed test data set
    @MainActor
    static func createWithTestData() -> ModelContainer {
        let schema = Schema([
            VisitedCountry.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create test data ModelContainer: \(error)")
        }

        for country in testCountries {
            container.mainContext.insert(country)
        }
        try? container.mainContext.save()

        return container
    }

    private static var testCountries: [VisitedCountry] {
        [
            VisitedCountry(
                alpha2: "FR",
                dateVisited: testDate(year: 2023, month: 6, day: 14),
                notes: "Visited Paris, saw the Eiffel Tower!"
            ),
            VisitedCountry(
                alpha2: "JP",
                dateVisited: testDate(year: 2024, month: 4, day: 2),
                notes: "Cherry blossoms in Kyoto and sushi in Tokyo."
            ),
            VisitedCountry(
                alpha2: "US",
                dateVisited: testDate(year: 2025, month: 9, day: 21),
                notes: "Road trip along the Pacific Coast Highway."
            ),
            VisitedCountry(
                alpha2: "IS",
                dateVisited: testDate(year: 2022, month: 2, day: 8),
                notes: "Chased the northern lights and soaked in a hot spring at -10°C."
            ),
            VisitedCountry(
                alpha2: "PE",
                dateVisited: testDate(year: 2023, month: 8, day: 17),
                notes: "Hiked the Inca Trail to Machu Picchu. Llamas everywhere."
            ),
            VisitedCountry(
                alpha2: "MA",
                dateVisited: testDate(year: 2024, month: 1, day: 11),
                notes: "Got lost in the Marrakech medina, slept under the stars in the Sahara."
            ),
            VisitedCountry(
                alpha2: "NZ",
                dateVisited: testDate(year: 2024, month: 12, day: 3),
                notes: "Bungee jumping in Queenstown and a detour to Hobbiton."
            ),
            VisitedCountry(
                alpha2: "VN",
                dateVisited: testDate(year: 2025, month: 3, day: 9),
                notes: "Overnight cruise in Ha Long Bay, best pho of my life in Hanoi."
            ),
            VisitedCountry(
                alpha2: "ZA",
                dateVisited: testDate(year: 2025, month: 5, day: 26),
                notes: "Safari in Kruger, spotted all Big Five. Table Mountain at sunset."
            ),
            VisitedCountry(
                alpha2: "NO",
                dateVisited: testDate(year: 2025, month: 7, day: 1),
                notes: "Midnight sun in the Lofoten Islands. Never figured out when to sleep."
            ),
            VisitedCountry(
                alpha2: "MX",
                dateVisited: testDate(year: 2025, month: 11, day: 2),
                notes: "Día de los Muertos in Oaxaca — mole, marigolds and mezcal."
            ),
            VisitedCountry(
                alpha2: "MN",
                dateVisited: testDate(year: 2026, month: 7, day: 12),
                notes: "Stayed in a ger with a nomad family and watched the Naadam festival."
            ),
            VisitedCountry(
                alpha2: "AR",
                dateVisited: testDate(year: 2026, month: 2, day: 19),
                notes: "Perito Moreno glacier, then tango and steak in Buenos Aires."
            ),
            VisitedCountry(
                alpha2: "JO",
                dateVisited: testDate(year: 2026, month: 4, day: 5),
                notes: "Walked through the Siq to Petra and floated in the Dead Sea."
            ),
            VisitedCountry(
                alpha2: "AQ",
                dateVisited: testDate(year: 2026, month: 1, day: 14),
                notes: "Expedition cruise to Antarctica. Penguins outnumbered people 1000:1."
            )
        ]
    }

    private static func testDate(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}
