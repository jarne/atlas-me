//
//  AddCountryView.swift
//  AtlasMe
//
//  Provides views that allow the user to search through unvisited countries, enter details
//  such as date of visit and notes, and add them to their list of visited countries.
//

import AtlasSharedKit
import SwiftData
import SwiftUI
import WidgetKit

struct AddCountryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var visitedCountries: [VisitedCountry]

    @State private var searchQuery = ""

    var body: some View {
        NavigationStack {
            List(filteredCountries) { country in
                NavigationLink(value: country) {
                    CountrySearchRow(country: country)
                }
            }
            .navigationTitle("Add Country")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchQuery, prompt: "Search countries...")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(for: Country.self) { country in
                AddCountryDetailsView(country: country)
            }
        }
    }

    private var filteredCountries: [Country] {
        let visitedCodes = Set(visitedCountries.map { $0.alpha2 })
        let available = Country.allCountries.filter { !visitedCodes.contains($0.alpha2) }

        if searchQuery.isEmpty {
            return available
        } else {
            return available.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                    $0.alpha2.localizedCaseInsensitiveContains(searchQuery) ||
                    $0.alpha3.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }
}

struct AddCountryDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let country: Country

    @State private var dateVisited = Date()
    @State private var notes = ""

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Text(country.flagEmoji)
                        .font(.system(size: 64))
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(country.name)
                            .font(.title2)
                            .bold()
                        Text("""
                        Latitude: \(country.latitude, specifier: "%.4f")
                        Longitude: \(country.longitude, specifier: "%.4f")
                        """)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            Section(header: Text("Travel Details")) {
                DatePicker("First Visited", selection: $dateVisited, in: ...Date(), displayedComponents: .date)
            }

            Section(header: Text("Travel Notes (Optional)")) {
                TextField("What did you do there? Favorite places?", text: $notes, axis: .vertical)
                    .lineLimit(3 ... 8)
            }
        }
        .navigationTitle(country.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveVisit()
                }
                .bold()
            }
        }
    }

    private func saveVisit() {
        let visited = VisitedCountry(
            alpha2: country.alpha2,
            dateVisited: dateVisited,
            notes: notes
        )
        modelContext.insert(visited)
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()

        dismiss()
    }
}

struct CountrySearchRow: View {
    let country: Country

    var body: some View {
        HStack(spacing: 16) {
            Text(country.flagEmoji)
                .font(.system(size: 32))
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(country.name)
                    .font(.headline)
                Text("ISO: \(country.alpha2)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
