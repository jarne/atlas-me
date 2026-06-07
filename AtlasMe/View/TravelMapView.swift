//
//  TravelMapView.swift
//  AtlasMe
//
//  Renders an interactive map marking all visited countries with their flag emojis.
//  It allows users to tap annotations to view summary cards and navigate to details.
//

import SwiftUI
import MapKit
import SwiftData

struct TravelMapView: View {
    @Query private var visitedCountries: [VisitedCountry]
    
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedCountry: VisitedCountry? = nil
    @State private var isShowingDetail = false
    
    @StateObject private var borderLoader = CountryBorderLoader.shared
    
    private var visitedAlpha2s: Set<String> {
        Set(visitedCountries.map { $0.alpha2.uppercased() })
    }
    
    private var mask: MKPolygon? {
        let worldCoordinates = [
            CLLocationCoordinate2D(latitude: 90, longitude: 0),
            CLLocationCoordinate2D(latitude: 90, longitude: 180),
            CLLocationCoordinate2D(latitude: -90, longitude: 180),
            CLLocationCoordinate2D(latitude: -90, longitude: 0),
            CLLocationCoordinate2D(latitude: -90, longitude: -180),
            CLLocationCoordinate2D(latitude: 90, longitude: -180)
        ]
        
        var visitedPolygons: [MKPolygon] = []
        for alpha2 in visitedAlpha2s {
            if let countryPolygons = borderLoader.borders[alpha2] {
                visitedPolygons.append(contentsOf: countryPolygons)
            }
        }
        
        return MKPolygon(coordinates: worldCoordinates, count: worldCoordinates.count, interiorPolygons: visitedPolygons.isEmpty ? nil : visitedPolygons)
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $position, bounds: MapCameraBounds(
                    minimumDistance: 10000000,
                    maximumDistance: 50000000
                ), interactionModes: [.pan, .zoom], selection: $selectedCountry) {
                    // 1. Draw the world-wide mask with holes for visited countries
                    if let m = mask {
                        MapPolygon(m)
                            .foregroundStyle(Color.black.opacity(0.4))
                    }
                    
                    // 2. Draw highlight strokes only for visited countries
                    ForEach(borderLoader.borders.keys.sorted().filter { visitedAlpha2s.contains($0) }, id: \.self) { alpha2 in
                        let isSelected = selectedCountry?.alpha2.uppercased() == alpha2
                        let polygons = borderLoader.borders[alpha2] ?? []
                        
                        ForEach(0..<polygons.count, id: \.self) { index in
                            MapPolygon(polygons[index])
                                .foregroundStyle(Color.clear)
                                .stroke(isSelected ? Color.accent : Color.clear, lineWidth: 3)
                        }
                    }
                    
                    ForEach(visitedCountries) { country in
                        Annotation(country.name, coordinate: CLLocationCoordinate2D(latitude: country.latitude, longitude: country.longitude)) {
                            VStack(spacing: 4) {
                                Text(country.flagEmoji)
                                    .font(.system(size: 28))
                                    .padding(8)
                                    .background(Color(.systemBackground))
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedCountry?.id == country.id ? Color.accent : Color.clear, lineWidth: 3)
                                    )
                            }
                            .scaleEffect(selectedCountry?.id == country.id ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedCountry)
                        }
                        .tag(country)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .ignoresSafeArea(edges: .horizontal)
                
                // Top Empty State Hint
                if visitedCountries.isEmpty {
                    Text("No visited countries yet. Add some in the Travels tab!")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .padding(.top, 16)
                }
                
                // Bottom Info Card when a country is selected
                VStack {
                    Spacer()
                    if let selected = selectedCountry {
                        selectedCountryCard(selected)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                            .padding()
                    }
                }
            }
            .navigationTitle("Travel Map")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isShowingDetail) {
                if let selected = selectedCountry {
                    CountryDetailView(visitedCountry: selected)
                }
            }
            .onAppear {
                borderLoader.loadBordersIfNeeded()
            }
            .onChange(of: selectedCountry) { _, newValue in
                if let country = newValue {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        position = .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: country.latitude, longitude: country.longitude),
                            span: MKCoordinateSpan(latitudeDelta: 20.0, longitudeDelta: 20.0)
                        ))
                    }
                }
            }
        }
    }
    
    private var isSelectedCountryValid: Bool {
        guard let selected = selectedCountry else { return false }
        return visitedCountries.contains { $0.id == selected.id }
    }
    
    private func selectedCountryCard(_ country: VisitedCountry) -> some View {
        HStack(spacing: 16) {
            Text(country.flagEmoji)
                .font(.system(size: 40))
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(country.name)
                    .font(.headline)
                
                Text("Visited \(country.dateVisited, format: Date.FormatStyle(date: .abbreviated))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !country.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(country.notes)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Button {
                isShowingDetail = true
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title)
                    .foregroundColor(.accent)
            }
            .buttonStyle(.plain)
            
            Button {
                withAnimation {
                    selectedCountry = nil
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
}

