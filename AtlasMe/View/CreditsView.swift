//
//  CreditsView.swift
//  AtlasMe
//
//  Displays credits and open source sources used in the app, with links to data sources and GitHub.
//

import SwiftUI

struct CreditsView: View {
    @Environment(\.openURL) private var openURL

    var appName: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "Unknown App"
    }

    var appVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "Unknown Version"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header/Logo Section
                VStack(spacing: 16) {
                    Image(systemName: "info.bubble.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor, Color("AccentSecondColor", bundle: .main)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(20)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Circle())
                        .shadow(color: Color.accentColor.opacity(0.15), radius: 10, x: 0, y: 5)

                    Text(appName)
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)

                    Text("Version \(appVersion)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)

                // About section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("""
                    Atlas & Me is an open-source, privacy-first visited countries journal and \
                    statistics tracker for iOS. It processes all your personal data offline and directly \
                    on your device, including local photo scanning.
                    """)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                }

                // Data Sources section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Sources")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("The country boundaries on the map are sourced from open data datasets:")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)

                    VStack(spacing: 12) {
                        LinkButton(
                            title: "Geo-Countries Dataset",
                            subtitle: "Map borders in GeoJSON format",
                            icon: "map.fill",
                            url: "https://github.com/datasets/geo-countries"
                        )

                        LinkButton(
                            title: "Natural Earth",
                            subtitle: "Public domain map data",
                            icon: "globe.europe.africa.fill",
                            url: "https://www.naturalearthdata.com"
                        )
                    }
                    .padding(.top, 4)
                }

                // Open Source & Contribution section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Open Source")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("""
                    This project is fully open source. You can view the code, contribute \
                    translations, request features, or report bugs directly on GitHub.
                    """)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)

                    Button {
                        if let url = URL(string: "https://github.com/jarne/atlas-me") {
                            openURL(url)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.up.forward.app.fill")
                                .font(.headline)
                            Text("View on GitHub")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.accentColor, Color("AccentSecondColor", bundle: .main)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Credits")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LinkButton: View {
    @Environment(\.openURL) private var openURL

    let title: String
    let subtitle: String
    let icon: String
    let url: String

    var body: some View {
        Button {
            if let targetURL = URL(string: url) {
                openURL(targetURL)
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    NavigationStack {
        CreditsView()
    }
}
