//
//  CountryDetailView.swift
//  AtlasMe
//
//  Displays detailed information about a visited country, including an interactive map of its location.
//  It allows users to edit their visit date and travel notes, or delete the visit entirely.
//

import MapKit
import SwiftData
import SwiftUI

struct CountryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var visitedCountry: VisitedCountry

    @State private var showingDeleteConfirmation = false

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Text(visitedCountry.flagEmoji)
                        .font(.system(size: 80))
                        .padding(16)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

                    Text(visitedCountry.name)
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)

                    Text("ISO: \(visitedCountry.alpha2) | \(visitedCountry.alpha3)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .listRowBackground(Color.clear)
            }

            Section(header: Text("Map Location")) {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: visitedCountry.latitude,
                                                   longitude: visitedCountry.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 12.0, longitudeDelta: 12.0)
                ))) {
                    Marker(visitedCountry.name,
                           coordinate: CLLocationCoordinate2D(latitude: visitedCountry.latitude,
                                                              longitude: visitedCountry.longitude))
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .listRowInsets(EdgeInsets())
            }

            Section(header: Text("Travel Details")) {
                DatePicker("First Visited", selection: $visitedCountry.dateVisited,
                           in: ...Date(), displayedComponents: .date)
            }

            Section(header: Text("Travel Notes")) {
                TextField("What did you do there?", text: $visitedCountry.notes, axis: .vertical)
                    .lineLimit(3 ... 8)
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Visit")
                            .bold()
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(visitedCountry.name)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Are you sure you want to delete this visit?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteVisit()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove \(visitedCountry.name) from your travelled list.")
        }
    }

    private func deleteVisit() {
        modelContext.delete(visitedCountry)
        dismiss()
    }
}
