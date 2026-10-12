//
//  AtlasMeUIMarketingScreenshots.swift
//  AtlasMeUITests
//
//  Captures App Store screenshots via fastlane snapshot.
//  Launches the app with fixed test data, then navigates Home, Travel List and Map,
//  taking a screenshot of each view.
//

import XCTest

final class AtlasMeUIMarketingScreenshots: XCTestCase {
    private enum Tab: Int {
        case home = 0
        case countries = 1
        case map = 2
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMarketingScreenshots() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments.append("-UseTestData")
        app.launch()

        select(.home, in: app)
        snapshot("01HomeView")

        select(.countries, in: app)
        snapshot("02TravelListView")

        select(.map, in: app)
        // Give MapKit time to render the map tiles and country borders
        sleep(3)
        snapshot("03TravelMapView")
    }

    @MainActor
    private func select(_ tab: Tab, in app: XCUIApplication) {
        let button = app.tabBars.buttons.element(boundBy: tab.rawValue)
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Tab \(tab) not found")
        button.tap()
    }
}
