//
//  TravelListView.swift
//  AtlasMe
//
//  Displays a searchable and sortable list of all visited countries, alongside a header card
//  that calculates and shows the user's travel stats and exploration progress.
//

import SwiftUI
import SwiftData

struct TravelListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var visitedCountries: [VisitedCountry]
    
    @State private var isShowingAddSheet = false
    @State private var isShowingImportSheet = false
    @State private var searchText = ""
    @State private var sortOption: SortOption = .dateNewest
    
    enum SortOption: String, CaseIterable, Identifiable {
        case dateNewest = "Date (Newest)"
        case dateOldest = "Date (Oldest)"
        case nameAZ = "Name (A-Z)"
        case nameZA = "Name (Z-A)"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if sortedAndFilteredCountries.isEmpty {
                    ContentUnavailableView {
                        Label(
                            searchText.isEmpty ? "No Travels Yet" : "No Matches",
                            systemImage: searchText.isEmpty ? "airplane.circle" : "magnifyingglass"
                        )
                    } description: {
                        Text(
                            searchText.isEmpty
                                ? "Start tracking your journeys by adding a country you've visited!"
                                : "Try searching for a different country."
                        )
                    } actions: {
                        if searchText.isEmpty {
                            Button("Add My First Country") {
                                isShowingAddSheet = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                    }
                } else {
                    List {
                        // Header Stats Card
                        statsHeaderCard
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        
                        ForEach(sortedAndFilteredCountries) { country in
                            NavigationLink(destination: CountryDetailView(visitedCountry: country)) {
                                HStack(spacing: 16) {
                                    Text(country.flagEmoji)
                                        .font(.system(size: 36))
                                        .padding(8)
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
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteVisitedCountries)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Travels")
            .searchable(text: $searchText, prompt: "Search visited countries...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isShowingImportSheet = true
                    } label: {
                        Image(systemName: "photo.badge.plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Sort By", selection: $sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down.circle")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSheet) {
                AddCountryView()
            }
            .sheet(isPresented: $isShowingImportSheet) {
                PhotoImportView()
            }
        }
    }
    
    private var sortedAndFilteredCountries: [VisitedCountry] {
        var result = visitedCountries
        
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch sortOption {
        case .dateNewest:
            result.sort { $0.dateVisited > $1.dateVisited }
        case .dateOldest:
            result.sort { $0.dateVisited < $1.dateVisited }
        case .nameAZ:
            result.sort { $0.name < $1.name }
        case .nameZA:
            result.sort { $0.name > $1.name }
        }
        
        return result
    }
    
    private var statsHeaderCard: some View {
        let totalOfficial = Country.allCountries.count
        let visitedCount = visitedCountries.count
        let percentage = totalOfficial > 0 ? (Double(visitedCount) / Double(totalOfficial)) * 100.0 : 0.0
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WORLD EXPLORER")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(1.5)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(visitedCount)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                        Text("/ \(totalOfficial) Countries")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Globe badge
                Image(systemName: "globe.europe.africa.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(percentage, specifier: "%.1f")% of the world visited")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                ProgressView(value: percentage, total: 100.0)
                    .tint(.white)
                    .background(Color.white.opacity(0.4))
                    .clipShape(Capsule())
            }
        }
        .foregroundColor(.white)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.accent, Color("SecondaryColor")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.accent.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
    
    private func deleteVisitedCountries(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let countryToDelete = sortedAndFilteredCountries[index]
                modelContext.delete(countryToDelete)
            }
        }
    }
}
