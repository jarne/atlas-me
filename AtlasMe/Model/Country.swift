//
//  Country.swift
//  AtlasMe
//
//  Defines the Country model which represents static country information, such as ISO codes,
//  geographic coordinates, and a utility to generate the corresponding flag emoji.
//

import Foundation

struct Country: Identifiable, Codable, Hashable {
    var id: String {
        alpha2
    }

    let name: String
    let alpha2: String
    let alpha3: String
    let latitude: Double
    let longitude: Double

    var flagEmoji: String {
        let base: UInt32 = 127_397
        var flagString = ""
        for scalar in alpha2.uppercased().unicodeScalars {
            if let scalar = UnicodeScalar(base + scalar.value) {
                flagString.unicodeScalars.append(scalar)
            }
        }
        return flagString
    }
}
