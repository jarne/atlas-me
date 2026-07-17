//
//  StatisticsCalculations.swift
//  AtlasMe
//
//  A utility class that calculates and formats travel statistics - such as total
//  counts, velocity, peak year, and notable milestones - from an array of visited countries.
//

import SwiftData
import SwiftUI

public final class StatisticsCalculations {
    private let visitedCountries: [VisitedCountry]

    public init(visitedCountries: [VisitedCountry]) {
        self.visitedCountries = visitedCountries
    }

    public let totalOfficial = Country.allCountries.count

    public var visitedCount: Int {
        return visitedCountries.count
    }

    public var remainingCount: Int {
        return max(0, totalOfficial - visitedCount)
    }

    public var velocityString: String {
        guard !visitedCountries.isEmpty else { return "0.0" }
        let dates = visitedCountries.map { $0.dateVisited }
        guard let minDate = dates.min() else { return "0.0" }
        let yearsElapsed = max(Date().timeIntervalSince(minDate) / (365.25 * 24 * 3600), 1.0)
        return String(format: "%.1f", Double(visitedCountries.count) / yearsElapsed)
    }

    public var vintageYearInfo: (year: String, subtitle: String) {
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

    public var pioneerString: String {
        if let pioneer = visitedCountries.min(by: { $0.dateVisited < $1.dateVisited }) {
            return "\(pioneer.flagEmoji) \(pioneer.name)"
        }
        return String(localized: "N/A")
    }

    public var latestAdditionString: String {
        if let latest = visitedCountries.max(by: { $0.dateVisited < $1.dateVisited }) {
            return "\(latest.flagEmoji) \(latest.name)"
        }
        return String(localized: "N/A")
    }
}
