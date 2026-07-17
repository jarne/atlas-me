//
//  MainExplorerCard.swift
//  AtlasMe
//
//  A reusable progress card that displays the user's total visited countries count,
//  computing a formatted percentage alongside a custom gradient and a white ProgressView.
//

import SwiftUI

public struct MainExplorerCard: View {
    let visitedCount: Int
    let totalOfficial: Int

    public init(visitedCount: Int, totalOfficial: Int) {
        self.visitedCount = visitedCount
        self.totalOfficial = totalOfficial
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MainExplorerCardContent(visitedCount: visitedCount, totalOfficial: totalOfficial)
        }
        .foregroundColor(.white)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.accent, Color("AccentSecondColor")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.accent.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
}

public struct MainExplorerCardContent: View {
    let visitedCount: Int
    let totalOfficial: Int

    public init(visitedCount: Int, totalOfficial: Int) {
        self.visitedCount = visitedCount
        self.totalOfficial = totalOfficial
    }

    private var percentage: Double {
        totalOfficial > 0 ? (Double(visitedCount) / Double(totalOfficial)) * 100.0 : 0.0
    }

    private var formattedPercentage: String {
        (percentage / 100).formatted(.percent.precision(.fractionLength(1)))
    }

    public var body: some View {
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
                Text("\(formattedPercentage) of the world visited")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()
            }

            ProgressView(value: percentage, total: 100.0)
                .tint(.white)
                .background(Color.white.opacity(0.6))
                .clipShape(Capsule())
        }
    }
}
