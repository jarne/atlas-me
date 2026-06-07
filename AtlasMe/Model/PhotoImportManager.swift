//
//  PhotoImportManager.swift
//  AtlasMe
//
//  Manages importing visited countries automatically by scanning the user's
//  photo library for geotagged images, reverse geocoding them offline,
//  and saving new countries with the photo's creation date.
//

import Foundation
import Photos
import SwiftData
import CoreLocation
import Combine

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
        guard let modelContext = modelContext else { return }
        status = .loadingBorders
        progress = 0.0
        processedCount = 0
        totalCount = 0
        importedCountriesCount = 0
        
        // Retrieve existing codes on MainActor first
        let descriptor = FetchDescriptor<VisitedCountry>()
        let visited = try? modelContext.fetch(descriptor)
        let existingCodes = Set(visited?.map { $0.alpha2.uppercased() } ?? [])
        
        Task {
            // 1. Ensure borders are loaded
            if CountryBorderLoader.shared.borders.isEmpty {
                CountryBorderLoader.shared.loadBordersIfNeeded()
                while CountryBorderLoader.shared.isLoading {
                    try? await Task.sleep(nanoseconds: 50_000_000) // 50ms sleep
                }
            }
            
            let borders = CountryBorderLoader.shared.borders
            guard !borders.isEmpty else {
                self.status = .completed(importedCount: 0)
                return
            }
            
            self.status = .importing
            
            // 2. Perform photolibrary scan in detached background task
            let result = await Task.detached(priority: .userInitiated) { () -> (imports: [(alpha2: String, date: Date)], totalCount: Int, photosWithLocationCount: Int) in
                let options = PHFetchOptions()
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                let assets = PHAsset.fetchAssets(with: .image, options: options)
                
                let count = assets.count
                guard count > 0 else {
                    return ([], 0, 0)
                }
                
                var visitedSet = existingCodes
                var newlyImportedSet: Set<String> = []
                var importsToSave: [(alpha2: String, date: Date)] = []
                var photosWithLocationCount = 0
                
                for i in 0..<count {
                    let asset = assets.object(at: i)
                    if let location = asset.location, let date = asset.creationDate {
                        photosWithLocationCount += 1
                        let coord = location.coordinate
                        if let alpha2 = CountryBorderLoader.countryCode(for: coord, in: borders) {
                            let upperAlpha2 = alpha2.uppercased()
                            if !visitedSet.contains(upperAlpha2) {
                                visitedSet.insert(upperAlpha2)
                                newlyImportedSet.insert(upperAlpha2)
                                importsToSave.append((alpha2: upperAlpha2, date: date))
                            }
                        }
                    }
                    
                    // Throttle MainActor UI updates
                    if i % 10 == 0 || i == count - 1 {
                        let progressVal = Double(i + 1) / Double(count)
                        let processedVal = i + 1
                        let importedVal = newlyImportedSet.count
                        
                        Task { @MainActor in
                            self.progress = progressVal
                            self.processedCount = processedVal
                            self.importedCountriesCount = importedVal
                        }
                    }
                }
                
                return (importsToSave, count, photosWithLocationCount)
            }.value
            
            if result.totalCount == 0 || result.photosWithLocationCount == 0 {
                self.status = .noPhotosWithLocation
                return
            }
            
            // 3. Batch insert new countries on MainActor
            for importData in result.imports {
                let newVisited = VisitedCountry(
                    alpha2: importData.alpha2,
                    dateVisited: importData.date,
                    notes: "Imported from Photo Library"
                )
                modelContext.insert(newVisited)
            }
            
            try? modelContext.save()
            self.status = .completed(importedCount: result.imports.count)
        }
    }
    
    func reset() {
        status = .idle
        progress = 0.0
        processedCount = 0
        totalCount = 0
        importedCountriesCount = 0
    }
}
