//
//  StatisticsWidgetsBundle.swift
//  StatisticsWidgets
//
//  A configuration structure that bundles and entry-points multiple Home
//  Screen widgets for the application.
//

import SwiftUI
import WidgetKit

@main
struct StatisticsWidgetsBundle: WidgetBundle {
    var body: some Widget {
        MainExplorerWidget()
        TravelInsightsWidget()
    }
}
