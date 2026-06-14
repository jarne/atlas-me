//
//  CountryBorderLoader.swift
//  AtlasMe
//
//  This file handles the loading and parsing of the countries.geojson file, converting
//  the geographic data into MapKit MKPolygons for rendering country borders.
//
//  The data is sourced from: https://github.com/datasets/geo-countries/blob/main/data/countries.geojson
//  under the Open Data Commons Public Domain Dedication and License, with the original data
//  provided by Natural Earth (https://www.naturalearthdata.com), Lexman and the Open Knowledge Foundation.
//

import Combine
import Foundation
import MapKit

@MainActor
class CountryBorderLoader: ObservableObject {
    static let shared = CountryBorderLoader()

    @Published var borders: [String: [MKPolygon]] = [:] // Keyed by alpha2 code (uppercase)
    @Published var isLoading = false

    private init() {}

    func loadBordersIfNeeded() {
        guard borders.isEmpty, !isLoading else { return }
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

    nonisolated static func countryCode(
        for coordinate: CLLocationCoordinate2D,
        in borders: [String: [MKPolygon]]
    ) -> String? {
        for (alpha2, polygons) in borders {
            for polygon in polygons where contains(coordinate: coordinate, polygon: polygon) {
                return alpha2
            }
        }
        return nil
    }

    private nonisolated static func contains(coordinate: CLLocationCoordinate2D, polygon: MKPolygon) -> Bool {
        let mapPoint = MKMapPoint(coordinate)
        if !polygon.boundingMapRect.contains(mapPoint) {
            return false
        }

        var coords = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(),
                                              count: polygon.pointCount)
        polygon.getCoordinates(&coords, range: NSRange(location: 0, length: polygon.pointCount))

        guard isPointInPolygon(coordinate, vertices: coords)
        else {
            return false
        }

        if let interiorPolygons = polygon.interiorPolygons {
            for hole in interiorPolygons where contains(coordinate: coordinate, polygon: hole) {
                return false
            }
        }

        return true
    }

    private nonisolated static func isPointInPolygon(
        _ point: CLLocationCoordinate2D,
        vertices: [CLLocationCoordinate2D]
    ) -> Bool {
        guard vertices.count > 2 else { return false }
        var inside = false
        var previous = vertices.count - 1
        for current in 0 ..< vertices.count {
            let currentVertex = vertices[current]
            let previousVertex = vertices[previous]

            let intersect = ((currentVertex.longitude > point.longitude) !=
                (previousVertex.longitude > point.longitude))
                && (point.latitude < (previousVertex.latitude - currentVertex.latitude) *
                    (point.longitude - currentVertex.longitude) /
                    (previousVertex.longitude - currentVertex.longitude) + currentVertex.latitude)
            if intersect {
                inside = !inside
            }
            previous = current
        }
        return inside
    }

    private nonisolated func parseGeoJSON() -> [String: [MKPolygon]] {
        guard let url = Bundle.main.url(forResource: "countries", withExtension: "geojson"),
              let data = try? Data(contentsOf: url)
        else {
            return [:]
        }

        let decoder = JSONDecoder()
        guard let featureCollection = try? decoder.decode(GeoJSONFeatureCollection.self, from: data)
        else {
            return [:]
        }

        var result: [String: [MKPolygon]] = [:]

        for feature in featureCollection.features {
            guard let alpha2 = feature.properties.iso_a2?.uppercased() else { continue }

            var polygons: [MKPolygon] = []

            switch feature.geometry.coordinates {
            case let .polygon(rings):
                if let polygon = createMKPolygon(fromRings: rings) {
                    polygons.append(polygon)
                }
            case let .multiPolygon(multipolygonRings):
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

    private nonisolated func createMKPolygon(fromRings rings: [[[Double]]]) -> MKPolygon? {
        guard !rings.isEmpty else { return nil }

        // The first ring is the exterior boundary
        let exteriorCoordinates = rings[0].map { cleanCoordinate($0) }

        // The remaining rings are interior holes
        let interiorPolygons = rings.dropFirst().compactMap { ring -> MKPolygon? in
            let coords = ring.map { cleanCoordinate($0) }
            guard !coords.isEmpty else { return nil }
            return MKPolygon(coordinates: coords, count: coords.count)
        }

        return MKPolygon(coordinates: exteriorCoordinates, count: exteriorCoordinates.count,
                         interiorPolygons: interiorPolygons.isEmpty ? nil : interiorPolygons)
    }

    /// "The Fiji Fix"
    /// Fiji sits directly on the international date line (the 180th meridian).
    /// When MapKit processes these coordinates, it normalizes anything exceeding 180.0 to a negative
    /// longitude (e.g. -179.999999...). Within a single polygon, switching between +179.4 and -179.9
    /// triggers a coordinate sign-flip.
    private nonisolated func cleanCoordinate(_ raw: [Double]) -> CLLocationCoordinate2D {
        let lat = raw[1]
        var lon = raw[0]
        if lon >= 180.0 {
            lon = 179.9999
        } else if lon <= -180.0 {
            lon = -179.9999
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
