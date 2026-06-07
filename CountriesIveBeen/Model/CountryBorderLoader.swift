//
//  CountryBorderLoader.swift
//  CountriesIveBeen
//
//  This file handles the loading and parsing of the countries.geojson file, converting
//  the geographic data into MapKit MKPolygons for rendering country borders.
//

import Foundation
import MapKit
import Combine

@MainActor
class CountryBorderLoader: ObservableObject {
    static let shared = CountryBorderLoader()
    
    @Published var borders: [String: [MKPolygon]] = [:] // Keyed by alpha2 code (uppercase)
    @Published var isLoading = false
    
    private init() {}
    
    func loadBordersIfNeeded() {
        guard borders.isEmpty && !isLoading else { return }
        isLoading = true
        
        Task.detached(priority: .userInitiated) {
            let loadedBorders = self.parseGeoJSON()
            await MainActor.run {
                self.borders = loadedBorders
                self.isLoading = false
            }
        }
    }
    
    nonisolated private func parseGeoJSON() -> [String: [MKPolygon]] {
        guard let url = Bundle.main.url(forResource: "countries", withExtension: "geojson"),
              let data = try? Data(contentsOf: url) else {
            return [:]
        }
        
        let decoder = JSONDecoder()
        guard let featureCollection = try? decoder.decode(GeoJSONFeatureCollection.self, from: data) else {
            return [:]
        }
        
        var result: [String: [MKPolygon]] = [:]
        
        for feature in featureCollection.features {
            guard let alpha2 = feature.properties.iso_a2?.uppercased() else { continue }
            
            var polygons: [MKPolygon] = []
            
            switch feature.geometry.coordinates {
            case .polygon(let rings):
                if let polygon = createMKPolygon(fromRings: rings) {
                    polygons.append(polygon)
                }
            case .multiPolygon(let multipolygonRings):
                for rings in multipolygonRings {
                    if let polygon = createMKPolygon(fromRings: rings) {
                        polygons.append(polygon)
                    }
                }
            }
            
            result[alpha2] = polygons
        }
        
        return result
    }
    
    nonisolated private func createMKPolygon(fromRings rings: [[[Double]]]) -> MKPolygon? {
        guard !rings.isEmpty else { return nil }
        
        // The first ring is the exterior boundary
        let exteriorCoordinates = rings[0].map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
        
        // The remaining rings are interior holes
        let interiorPolygons = rings.dropFirst().compactMap { ring -> MKPolygon? in
            let coords = ring.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
            guard !coords.isEmpty else { return nil }
            return MKPolygon(coordinates: coords, count: coords.count)
        }
        
        return MKPolygon(coordinates: exteriorCoordinates, count: exteriorCoordinates.count, interiorPolygons: interiorPolygons.isEmpty ? nil : interiorPolygons)
    }
}

// MARK: - GeoJSON Decodable Structs

private struct GeoJSONFeatureCollection: Decodable {
    let type: String
    let features: [GeoJSONFeature]
}

private struct GeoJSONFeature: Decodable {
    let type: String
    let properties: GeoJSONProperties
    let geometry: GeoJSONGeometry
}

private struct GeoJSONProperties: Decodable {
    let iso_a2: String?
    let iso_a3: String?
    let name: String?
}

private struct GeoJSONGeometry: Decodable {
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

private enum GeoJSONCoordinates {
    case polygon([[[Double]]])
    case multiPolygon([[[[Double]]]])
}
