//
//  PhotoImportManager.swift
//  AtlasMe
//
//  Manages importing visited countries automatically by scanning the user's
//  photo library for geotagged images, reverse geocoding them offline,
//  and saving new countries with the photo's creation date.
//

import Combine
import CoreLocation
import Foundation
import MapKit
import Photos
import SwiftData

@MainActor
class PhotoImportManager: ObservableObject {
    @Published var status: ImportStatus = .idle
    @Published var progress: Double = 0.0
    @Published var processedCount: Int = 0
    @Published var totalCount: Int = 0
    @Published var importedCountriesCount: Int = 0

    enum ImportStatus: Equatable {
        case idle
        case requestingAuthorization
        case denied
        case loadingBorders
        case importing
        case completed(importedCount: Int)
        case noPhotosWithLocation
    }

    var modelContext: ModelContext?

    func startImport() {
        status = .requestingAuthorization

        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] authStatus in
            guard let self = self else { return }

            Task { @MainActor in
                switch authStatus {
                case .authorized, .limited:
                    self.processPhotos()
                case .denied, .restricted:
                    self.status = .denied
                case .notDetermined:
                    self.status = .idle
                @unknown default:
                    self.status = .idle
                }
            }
        }
    }

    private func processPhotos() {
        guard modelContext != nil else { return }
        status = .loadingBorders
        progress = 0.0
        processedCount = 0
        totalCount = 0
        importedCountriesCount = 0

        let existingCodes = fetchExistingCountryCodes()

        Task {
            guard let borders = await ensureBordersLoaded()
            else {
                self.status = .completed(importedCount: 0)
                return
            }

            self.status = .importing

            let result = await scanPhotoLibrary(existingCodes: existingCodes, borders: borders)

            if result.totalCount == 0 || result.photosWithLocationCount == 0 {
                self.status = .noPhotosWithLocation
                return
            }

            saveImportedCountries(result.imports)
            self.status = .completed(importedCount: result.imports.count)
        }
    }

    private func fetchExistingCountryCodes() -> Set<String> {
        guard let modelContext = modelContext else { return [] }
        let descriptor = FetchDescriptor<VisitedCountry>()
        let visited = try? modelContext.fetch(descriptor)
        return Set(visited?.map { $0.alpha2.uppercased() } ?? [])
    }

    private func ensureBordersLoaded() async -> [String: [MKPolygon]]? {
        if CountryBorderLoader.shared.borders.isEmpty {
            CountryBorderLoader.shared.loadBordersIfNeeded()
            while CountryBorderLoader.shared.isLoading {
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms sleep
            }
        }
        let borders = CountryBorderLoader.shared.borders
        return borders.isEmpty ? nil : borders
    }

    struct ScanResult {
        let imports: [(alpha2: String, date: Date)]
        let totalCount: Int
        let photosWithLocationCount: Int
    }

    struct ScanState {
        var visitedSet: Set<String>
        var newlyImportedSet: Set<String>
        var importsToSave: [(alpha2: String, date: Date)]
        var photosWithLocationCount: Int
    }

    private func scanPhotoLibrary(
        existingCodes: Set<String>,
        borders: [String: [MKPolygon]]
    ) async -> ScanResult {
        await Task.detached(priority: .userInitiated) { [weak self] in
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            let assets = PHAsset.fetchAssets(with: .image, options: options)

            let count = assets.count
            guard count > 0 else {
                return ScanResult(imports: [], totalCount: 0, photosWithLocationCount: 0)
            }

            if let self {
                await MainActor.run {
                    self.totalCount = count
                }
            }

            var state = ScanState(
                visitedSet: existingCodes,
                newlyImportedSet: [],
                importsToSave: [],
                photosWithLocationCount: 0
            )

            for assetI in 0 ..< count {
                let asset = assets.object(at: assetI)
                Self.processAsset(
                    asset,
                    borders: borders,
                    state: &state
                )

                if assetI % 10 == 0 || assetI == count - 1 {
                    let importedVal = state.newlyImportedSet.count
                    if let self {
                        await self.updateUIProgress(index: assetI, count: count, newlyImportedCount: importedVal)
                    }
                }
            }

            return ScanResult(
                imports: state.importsToSave,
                totalCount: count,
                photosWithLocationCount: state.photosWithLocationCount
            )
        }.value
    }

    private nonisolated static func processAsset(
        _ asset: PHAsset,
        borders: [String: [MKPolygon]],
        state: inout ScanState
    ) {
        guard let location = asset.location, let date = asset.creationDate else { return }
        state.photosWithLocationCount += 1
        let coord = location.coordinate
        if let alpha2 = CountryBorderLoader.countryCode(for: coord, in: borders) {
            let upperAlpha2 = alpha2.uppercased()
            if !state.visitedSet.contains(upperAlpha2) {
                state.visitedSet.insert(upperAlpha2)
                state.newlyImportedSet.insert(upperAlpha2)
                state.importsToSave.append((alpha2: upperAlpha2, date: date))
            }
        }
    }

    private func updateUIProgress(index: Int, count: Int, newlyImportedCount: Int) {
        let progressVal = Double(index + 1) / Double(count)
        let processedVal = index + 1

        progress = progressVal
        processedCount = processedVal
        importedCountriesCount = newlyImportedCount
    }

    private func saveImportedCountries(_ imports: [(alpha2: String, date: Date)]) {
        guard let modelContext = modelContext else { return }
        for importData in imports {
            let newVisited = VisitedCountry(
                alpha2: importData.alpha2,
                dateVisited: importData.date,
                notes: String(localized: "Imported from Photo Library")
            )
            modelContext.insert(newVisited)
        }
        try? modelContext.save()
    }

    func reset() {
        status = .idle
        progress = 0.0
        processedCount = 0
        totalCount = 0
        importedCountriesCount = 0
    }
}
