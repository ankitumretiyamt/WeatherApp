//
//  WeatherAppUITests.swift
//  WeatherAppUITests
//
//  Created by Ankit Umretiya on 30/10/26.
//

import XCTest

final class WeatherAppUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testWeatherFlow() throws {
        let app = XCUIApplication()
        addUIInterruptionMonitor(withDescription: "Location permission") { alert in
            let button = alert.buttons["Allow While Using App"]
            if button.exists {
                button.tap()
                return true
            }
            return false
        }
        app.launch()
        app.tap()

        XCTAssertTrue(app.staticTexts["Feels like"].waitForExistence(timeout: 25))
        XCTAssertTrue(app.staticTexts["Humidity"].exists)
        XCTAssertTrue(app.staticTexts["Wind"].exists)
        XCTAssertTrue(app.staticTexts["UV index"].exists)
        attach(app, name: "Home")

        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Sunrise"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Sunset"].exists)
        attach(app, name: "Home daylight")

        app.buttons["Details"].tap()
        XCTAssertTrue(app.staticTexts["Temperature curve"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Wind"].exists)
        let nowChip = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Now'")).firstMatch
        XCTAssertTrue(nowChip.waitForExistence(timeout: 5))
        attach(app, name: "Details")

        app.buttons["Explore"].tap()
        let search = app.textFields["Search cities"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Paris")
        let paris = app.staticTexts["Paris"].firstMatch
        XCTAssertTrue(paris.waitForExistence(timeout: 20))
        attach(app, name: "Explore")
        paris.tap()

        let parisHeader = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Paris'")).firstMatch
        app.buttons["Home"].tap()
        XCTAssertTrue(parisHeader.waitForExistence(timeout: 20))
        app.buttons["Save city"].tap()
        attach(app, name: "Home Paris")

        app.swipeDown()
        let appearance = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Switch to'")).firstMatch
        if appearance.waitForExistence(timeout: 3) {
            appearance.tap()
            attach(app, name: "Appearance toggled")
        }

        app.buttons["Saved"].tap()
        XCTAssertTrue(app.staticTexts["7-day forecast"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Paris"].waitForExistence(timeout: 8))
        attach(app, name: "Saved")
    }

    @MainActor
    private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
