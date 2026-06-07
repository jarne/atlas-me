//
//  PhotoImportView.swift
//  AtlasMe
//
//  A user interface allowing users to import visited countries automatically
//  from the photo library. Features an interactive flow, real-time progress,
//  and privacy-focused messaging.
//

import SwiftUI
import SwiftData

struct PhotoImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var importManager = PhotoImportManager()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Top Visual Badge
                statusIconSection
                
                // Dynamic Status & Text Section
                statusContentSection
                
                Spacer()
                
                // Progress Bar (Visible during import)
                if importManager.status == .importing {
                    progressSection
                }
                
                // Action Buttons
                actionButtonSection
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .navigationTitle("Import from Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if importManager.status == .idle || isFinishedState {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            }
            .onDisappear {
                importManager.reset()
            }
        }
    }
    
    // Check if the current state is finished or completed
    private var isFinishedState: Bool {
        switch importManager.status {
        case .completed, .noPhotosWithLocation, .denied:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var statusIconSection: some View {
        ZStack {
            // Background Glow/Shadow
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.accent.opacity(0.15), Color("SecondaryColor").opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 160, height: 160)
            
            // Icon Background
            Circle()
                .fill(Color(.secondarySystemBackground))
                .frame(width: 120, height: 120)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            
            // State-based Icon
            Group {
                switch importManager.status {
                case .idle:
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.accent)
                case .requestingAuthorization:
                    ProgressView()
                        .scaleEffect(1.5)
                case .denied:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                case .loadingBorders:
                    ProgressView()
                        .scaleEffect(1.5)
                case .importing:
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundColor(Color("SecondaryColor"))
                case .completed(let count):
                    if count > 0 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accent)
                    }
                case .noPhotosWithLocation:
                    Image(systemName: "mappin.slash.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                }
            }
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    @ViewBuilder
    private var statusContentSection: some View {
        VStack(spacing: 12) {
            switch importManager.status {
            case .idle:
                Text("Discover Visited Countries")
                    .font(.title2)
                    .bold()
                
                Text("Scan the location metadata in your photo library to automatically add the countries you've travelled to, set with the date you visited them.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                privacyCard
                    .padding(.top, 8)
                
            case .requestingAuthorization:
                Text("Accessing Photos...")
                    .font(.headline)
                Text("Please authorize photo access if prompted.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
            case .denied:
                Text("Photo Access Denied")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.red)
                
                Text("To automatically import countries, please grant photo library access in Settings.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
            case .loadingBorders:
                Text("Preparing Country Data...")
                    .font(.headline)
                Text("Loading global geography coordinates for offline lookup.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
            case .importing:
                Text("Scanning Your Photos...")
                    .font(.title2)
                    .bold()
                
                HStack(spacing: 8) {
                    Text("Processed: **\(importManager.processedCount) / \(importManager.totalCount)**")
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("Found: **\(importManager.importedCountriesCount) new**")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
            case .completed(let count):
                Text("Import Complete!")
                    .font(.title2)
                    .bold()
                
                if count > 0 {
                    Text("Successfully added **\(count)** new countries to your travels list.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                } else {
                    Text("Scan finished, but no new countries were found. Your list is already up to date!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
            case .noPhotosWithLocation:
                Text("No Geotagged Photos")
                    .font(.title2)
                    .bold()
                
                Text("We couldn't find any photos with location coordinates in your library. Make sure location services are enabled for your camera.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .animation(.easeInOut, value: importManager.status)
    }
    
    private var privacyCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "hand.raised.fill")
                .font(.title3)
                .foregroundColor(.accent)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("100% Private & Secure")
                    .font(.subheadline)
                    .bold()
                Text("All photo location data is processed entirely offline on your device. Your photos are never uploaded or shared.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            ProgressView(value: importManager.progress, total: 1.0)
                .progressViewStyle(.linear)
                .tint(Color("SecondaryColor"))
            
            Text("\(Int(importManager.progress * 100))%")
                .font(.caption)
                .bold()
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .transition(.opacity)
    }
    
    @ViewBuilder
    private var actionButtonSection: some View {
        Group {
            switch importManager.status {
            case .idle:
                Button {
                    withAnimation {
                        importManager.modelContext = modelContext
                        importManager.startImport()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Start Import")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.accent, Color("SecondaryColor")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
            case .requestingAuthorization, .loadingBorders, .importing:
                EmptyView()
                
            case .denied:
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Open Settings")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .background(Color.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
            case .completed, .noPhotosWithLocation:
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Spacer()
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .background(Color.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .animation(.easeInOut, value: importManager.status)
    }
}

#Preview {
    PhotoImportView()
}
