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
final class VisitedCountry {
    @Attribute(.unique) var alpha2: String
    var dateVisited: Date
    var notes: String
    
    init(alpha2: String, dateVisited: Date = Date(), notes: String = "") {
        self.alpha2 = alpha2.uppercased()
        self.dateVisited = dateVisited
        self.notes = notes
    }
    
    // Dynamically retrieve static country information from CountryStaticList
    var countryInfo: Country? {
        Country.allCountries.first(where: { $0.alpha2 == self.alpha2 })
    }
    
    var name: String {
        countryInfo?.name ?? "Unknown Country"
    }
    
    var alpha3: String {
        countryInfo?.alpha3 ?? ""
    }
    
    var latitude: Double {
        countryInfo?.latitude ?? 0.0
    }
    
    var longitude: Double {
        countryInfo?.longitude ?? 0.0
    }
    
    var flagEmoji: String {
        let base : UInt32 = 127397
        var s = ""
        for v in alpha2.uppercased().unicodeScalars {
            if let scalar = UnicodeScalar(base + v.value) {
                s.unicodeScalars.append(scalar)
            }
        }
        return s
    }
}

