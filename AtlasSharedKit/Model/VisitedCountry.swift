//
//  VisitedCountry.swift
//  AtlasMe
//
//  Defines the persistent SwiftData model for countries visited by the user. It stores
//  the country's ISO 3166-1 alpha-2 code, the date of the visit, and custom travel notes.
//  Other static country details (like name, coordinates, etc.) are fetched dynamically
//  from CountryStaticList.
//

import Foundation
import SwiftData

@Model
public final class VisitedCountry {
    @Attribute(.unique) public var alpha2: String
    public var dateVisited: Date
    public var notes: String

    public init(alpha2: String, dateVisited: Date = Date(), notes: String = "") {
        self.alpha2 = alpha2.uppercased()
        self.dateVisited = dateVisited
        self.notes = notes
    }

    /// Dynamically retrieve static country information from CountryStaticList
    public var countryInfo: Country? {
        Country.allCountries.first(where: { $0.alpha2 == self.alpha2 })
    }

    public var name: String {
        countryInfo?.name ?? String(localized: "Unknown Country")
    }

    public var alpha3: String {
        countryInfo?.alpha3 ?? ""
    }

    public var latitude: Double {
        countryInfo?.latitude ?? 0.0
    }

    public var longitude: Double {
        countryInfo?.longitude ?? 0.0
    }

    public var flagEmoji: String {
        countryInfo?.flagEmoji ?? ""
    }
}
