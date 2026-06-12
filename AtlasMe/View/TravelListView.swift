//
//  TravelListView.swift
//  AtlasMe
//
//  Displays a searchable and sortable list of all visited countries, alongside a header card
//  that calculates and shows the user's travel stats and exploration progress.
//

import SwiftData
import SwiftUI

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

        var id: String {
            rawValue
        }

        var localizedName: String {
            switch self {
            case .dateNewest:
                return String(localized: "Date (Newest)")
            case .dateOldest:
                return String(localized: "Date (Oldest)")
            case .nameAZ:
                return String(localized: "Name (A-Z)")
            case .nameZA:
                return String(localized: "Name (Z-A)")
            }
        }
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
                        Section {
                            ForEach(sortedAndFilteredCountries) { country in
                                NavigationLink(destination: CountryDetailView(visitedCountry: country)) {
                                    VisitedCountryRow(country: country)
                                }
                            }
                            .onDelete(perform: deleteVisitedCountries)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Countries")
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
                                Text(option.localizedName).tag(option)
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

    private func deleteVisitedCountries(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let countryToDelete = sortedAndFilteredCountries[index]
                modelContext.delete(countryToDelete)
            }
        }
    }
}

struct VisitedCountryRow: View {
    let country: VisitedCountry

    var body: some View {
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
