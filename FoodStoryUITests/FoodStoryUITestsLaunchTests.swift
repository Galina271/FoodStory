//
//  FoodStoryUITestsLaunchTests.swift
//  FoodStoryUITests
//

import XCTest

final class FoodStoryUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool { true }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
    }
}
