//
//  Country.swift
//  AtlasMe
//
//  Defines the Country model which represents static country information, such as ISO codes,
//  geographic coordinates, and a utility to generate the corresponding flag emoji.
//

import Foundation

public struct Country: Identifiable, Codable, Hashable {
    public var id: String {
        alpha2
    }

    public let name: String
    public let alpha2: String
    public let alpha3: String
    public let latitude: Double
    public let longitude: Double

    public var flagEmoji: String {
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
