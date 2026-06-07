//
//  VisitedCountry.swift
//  CountriesIveBeen
//
//  Defines the persistent SwiftData model for countries visited by the user. It stores
//  the country's name, coordinates, code, the date of the visit, and custom travel notes.
//

import Foundation
import SwiftData

@Model
final class VisitedCountry {
    @Attribute(.unique) var alpha2: String
    var name: String
    var alpha3: String
    var latitude: Double
    var longitude: Double
    var dateVisited: Date
    var notes: String
    
    init(alpha2: String, name: String, alpha3: String, latitude: Double, longitude: Double, dateVisited: Date = Date(), notes: String = "") {
        self.alpha2 = alpha2.uppercased()
        self.name = name
        self.alpha3 = alpha3.uppercased()
        self.latitude = latitude
        self.longitude = longitude
        self.dateVisited = dateVisited
        self.notes = notes
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
