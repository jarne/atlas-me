//
//  GeoJSONModels.swift
//  AtlasMe
//
//  Decodable model structures representing GeoJSON feature collection geometry.
//  Kept in a separate file to ensure clean, non-isolated Decodable conformance
//  independent of MainActor UI classes.
//

import Foundation

nonisolated struct GeoJSONFeatureCollection: Decodable {
    let type: String
    let features: [GeoJSONFeature]
}

nonisolated struct GeoJSONFeature: Decodable {
    let type: String
    let properties: GeoJSONProperties
    let geometry: GeoJSONGeometry
}

nonisolated struct GeoJSONProperties: Decodable {
    let iso_a2: String?
    let iso_a3: String?
    let name: String?
}

nonisolated struct GeoJSONGeometry: Decodable {
    let type: String
    let coordinates: GeoJSONCoordinates
    
    enum CodingKeys: String, CodingKey {
        case type
        case coordinates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "Polygon":
            let coords = try container.decode([[[Double]]].self, forKey: .coordinates)
            coordinates = .polygon(coords)
        case "MultiPolygon":
            let coords = try container.decode([[[[Double]]]].self, forKey: .coordinates)
            coordinates = .multiPolygon(coords)
        default:
            throw DecodingError.dataCorruptedError(forKey: .coordinates, in: container, debugDescription: "Unknown geometry type")
        }
    }
}

nonisolated enum GeoJSONCoordinates {
    case polygon([[[Double]]])
    case multiPolygon([[[[Double]]]])
}
