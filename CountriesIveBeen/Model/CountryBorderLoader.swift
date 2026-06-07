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
    
    nonisolated func loadBordersDict() -> [String: [MKPolygon]] {
        return parseGeoJSON()
    }
    
    nonisolated static func countryCode(for coordinate: CLLocationCoordinate2D, in borders: [String: [MKPolygon]]) -> String? {
        for (alpha2, polygons) in borders {
            for polygon in polygons {
                if contains(coordinate: coordinate, polygon: polygon) {
                    return alpha2
                }
            }
        }
        return nil
    }
    
    nonisolated private static func contains(coordinate: CLLocationCoordinate2D, polygon: MKPolygon) -> Bool {
        let mapPoint = MKMapPoint(coordinate)
        if !polygon.boundingMapRect.contains(mapPoint) {
            return false
        }
        
        var coords = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: polygon.pointCount)
        polygon.getCoordinates(&coords, range: NSRange(location: 0, length: polygon.pointCount))
        
        guard isPointInPolygon(coordinate, vertices: coords) else {
            return false
        }
        
        if let interiorPolygons = polygon.interiorPolygons {
            for hole in interiorPolygons {
                if contains(coordinate: coordinate, polygon: hole) {
                    return false
                }
            }
        }
        
        return true
    }
    
    nonisolated private static func isPointInPolygon(_ point: CLLocationCoordinate2D, vertices: [CLLocationCoordinate2D]) -> Bool {
        guard vertices.count > 2 else { return false }
        var inside = false
        var j = vertices.count - 1
        for i in 0..<vertices.count {
            let pi = vertices[i]
            let pj = vertices[j]
            
            let intersect = ((pi.longitude > point.longitude) != (pj.longitude > point.longitude))
                && (point.latitude < (pj.latitude - pi.latitude) * (point.longitude - pi.longitude) / (pj.longitude - pi.longitude) + pi.latitude)
            if intersect {
                inside = !inside
            }
            j = i
        }
        return inside
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
