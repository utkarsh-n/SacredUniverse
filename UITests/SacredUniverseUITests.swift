import XCTest

/// These tests use an isolated preference suite. They verify the learner's
/// visible calculations and transitions, including what survives a fresh launch.
final class SacredUniverseUITests: XCTestCase {
    @MainActor
    func testCirclePredictionCanBeRevisedAndDiscoverySurvivesRelaunch() {
        let app = launch(reset: true)
        openLab("circle", in: app)
        expectPhase("observe", in: app)

        tap("beginExperiment", in: app)
        expectPhase("experiment", in: app)
        let prediction = app.buttons["makePrediction"]
        reveal(prediction, in: app)
        XCTAssertFalse(prediction.isEnabled, "A learner must change the experiment before predicting.")

        expectResult("360°", in: app)
        let original = result(in: app)
        tap("sampleAction", in: app)
        expectChangedResult(from: original, in: app)
        expectResult("180°", in: app)
        let explored = result(in: app)
        XCTAssertTrue(prediction.isEnabled)
        tap("makePrediction", in: app)
        expectPhase("predict", in: app)

        tap("answer0", in: app)
        expectPhase("predict", in: app)
        XCTAssertTrue(app.staticTexts["tryAgain"].waitForExistence(timeout: 5), "An incorrect prediction must give actionable feedback.")
        XCTAssertFalse(app.buttons["saveDiscovery"].exists, "An incorrect prediction must not save a discovery.")
        XCTAssertTrue(app.buttons["answer1"].exists, "The learner must be able to revise the answer.")
        tap("answer1", in: app)
        expectPhase("explain", in: app)
        tap("saveDiscovery", in: app)
        expectPhase("complete", in: app)
        returnHome(in: app)

        selectTab("Notebook", in: app)
        expectNotebookCircle(in: app)
        selectTab("Journey", in: app)
        let journeyCircle = app.buttons["journey-circle"]
        reveal(journeyCircle, in: app)
        journeyCircle.tap()
        attachScreenshot(named: "circle-stage-journey", in: app)
        expectPhase("complete", in: app)
        expectResult(explored, in: app)

        app.terminate()
        _ = launch(reset: false, application: app)
        selectTab("Notebook", in: app)
        expectNotebookCircle(in: app)
        selectTab("Universe", in: app)
        openLab("circle", in: app)
        expectPhase("complete", in: app)
        expectResult(explored, in: app)
    }

    @MainActor
    func testEveryLabChangesItsCalculationAndKeepsIndependentState() {
        let app = launch(reset: true)
        let kinds = ["circle", "time", "roots", "polygons", "solids", "precession", "scale", "pyramid"]
        var exploredResults: [String: String] = [:]

        for kind in kinds {
            XCTContext.runActivity(named: "Explore \(kind)") { _ in
                openLab(kind, in: app)
                expectPhase("observe", in: app)
                let initial = result(in: app)
                tap("beginExperiment", in: app)
                expectPhase("experiment", in: app)
                let prediction = app.buttons["makePrediction"]
                reveal(prediction, in: app)
                XCTAssertFalse(prediction.isEnabled, "\(kind) must require an actual parameter change.")

                tap("sampleAction", in: app)
                expectChangedResult(from: initial, in: app)
                expectPhase("experiment", in: app)
                XCTAssertTrue(prediction.isEnabled, "\(kind) must allow prediction after exploration.")
                exploredResults[kind] = result(in: app)
                returnHome(in: app)
            }
        }

        // Visiting a later experiment must not replace an earlier lab's values
        // or progress. Check both ends of the journey and a fresh process.
        for kind in ["circle", "pyramid"] {
            openLab(kind, in: app)
            expectPhase("experiment", in: app)
            if let expected = exploredResults[kind] {
                expectResult(expected, in: app)
            } else {
                XCTFail("Missing explored result for \(kind).")
            }
            returnHome(in: app)
        }

        app.terminate()
        _ = launch(reset: false, application: app)
        for kind in ["circle", "pyramid"] {
            openLab(kind, in: app)
            expectPhase("experiment", in: app)
            if let expected = exploredResults[kind] {
                expectResult(expected, in: app)
            } else {
                XCTFail("Missing explored result for \(kind).")
            }
            returnHome(in: app)
        }
        selectTab("Notebook", in: app)
        XCTAssertTrue(app.staticTexts["Your first discovery is waiting."].waitForExistence(timeout: 5), "Exploration alone must leave Notebook empty.")
        XCTAssertFalse(identified("discovery-circle", in: app).exists, "Exploration alone must not become a saved discovery.")
    }

    @MainActor
    func testSourceSheetDismissalPreservesExperiment() {
        let app = launch(reset: true)
        openLab("precession", in: app)
        tap("beginExperiment", in: app)
        tap("sampleAction", in: app)
        let explored = result(in: app)
        expectPhase("experiment", in: app)

        tap("sourceNotes", in: app)
        XCTAssertTrue(app.staticTexts["About this experiment"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["closeSheet"].waitForExistence(timeout: 5))
        app.buttons["closeSheet"].tap()

        expectPhase("experiment", in: app)
        expectResult(explored, in: app)
        tap("makePrediction", in: app)
        expectPhase("predict", in: app)
    }

    @MainActor
    func testSensorySettingsPersistWithoutChangingLearningState() {
        let app = launch(reset: true)
        openLab("time", in: app)
        tap("beginExperiment", in: app)
        tap("sampleAction", in: app)
        let explored = result(in: app)

        tap("sensorySettings", in: app)
        let sound = innerNativeSwitch("soundEnabled", in: app)
        let haptics = innerNativeSwitch("hapticsEnabled", in: app)
        attachScreenshot(named: "sensory-settings-before", in: app)
        expectSwitch(sound, value: "0")
        expectSwitch(haptics, value: "1")
        sound.tap()
        expectSwitch(sound, value: "1")
        haptics.tap()
        expectSwitch(haptics, value: "0")
        attachScreenshot(named: "sensory-settings-after", in: app)
        tap("closeSheet", in: app)
        expectPhase("experiment", in: app)
        expectResult(explored, in: app)

        app.terminate()
        _ = launch(reset: false, application: app)
        openLab("time", in: app)
        expectPhase("experiment", in: app)
        expectResult(explored, in: app)
        tap("sensorySettings", in: app)
        let restoredSound = innerNativeSwitch("soundEnabled", in: app)
        let restoredHaptics = innerNativeSwitch("hapticsEnabled", in: app)
        expectSwitch(restoredSound, value: "1")
        expectSwitch(restoredHaptics, value: "0")
        attachScreenshot(named: "sensory-settings-restored", in: app)
        // Leave the test suite silent after checking the preference survived.
        restoredSound.tap()
        expectSwitch(restoredSound, value: "0")
        tap("closeSheet", in: app)
        expectPhase("experiment", in: app)
        expectResult(explored, in: app)
    }

    @MainActor
    func testHomeScreenIconLaunchStaysForeground() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.terminate()
        let springBoard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        // A second Home action returns to the first Home Screen page, making the
        // following bounded lookup independent of the previously visible page.
        XCUIDevice.shared.press(.home)
        XCUIDevice.shared.press(.home)

        var opened = false
        for page in 0..<8 {
            let icon = springBoard.icons["Sacred Universe"]
            if icon.waitForExistence(timeout: 1), icon.isHittable {
                icon.tap()
                opened = true
                break
            }
            if page < 7 { springBoard.swipeLeft() }
        }
        if !opened {
            // The observed phone reaches App Library after these bounded left
            // swipes. Prefer its labelled search surface when accessibility
            // exposes it; the recording confirms the search bar's location
            // when SpringBoard instead reports a remote placeholder.
            let searchSurfaces = [
                springBoard.searchFields["App Library"],
                springBoard.buttons["App Library"],
                springBoard.staticTexts["App Library"]
            ]
            if let search = searchSurfaces.first(where: { $0.exists && $0.isHittable }) {
                search.tap()
            } else {
                springBoard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.115)).tap()
            }
            springBoard.typeText("Sacred Universe")
            attachScreenshot(named: "normal-launch-library-search", in: springBoard)
            let searchResults = [
                springBoard.icons["Sacred Universe"],
                springBoard.buttons["Sacred Universe"],
                springBoard.staticTexts["Sacred Universe"]
            ]
            for result in searchResults {
                if result.waitForExistence(timeout: 3), result.isHittable {
                    result.tap()
                    opened = true
                    break
                }
            }
            if !opened {
                let hierarchy = XCTAttachment(string: springBoard.debugDescription)
                hierarchy.name = "normal-launch-library-search-hierarchy"
                hierarchy.lifetime = .keepAlways
                add(hierarchy)
            }
        }
        XCTAssertTrue(opened, "Test environment: Sacred Universe was not reachable on eight Home Screen pages or as a hittable App Library search result. See the retained search screenshot and hierarchy; app launch was not attempted.")
        guard opened else { return }

        // The app is opened from system UI, with its normal launch behavior and
        // production preferences. No launch(), activate(), or reset arguments.
        XCTAssertTrue(app.tabBars.buttons["Universe"].waitForExistence(timeout: 15), "A normal icon launch must render Universe.")
        XCTAssertEqual(app.state, .runningForeground, "The normal icon-launched app must stay in the foreground.")
        attachScreenshot(named: "normal-homepage", in: app)
        openLab("circle", in: app)
        attachScreenshot(named: "normal-circle-stage", in: app)
        tap("sourceNotes", in: app)
        XCTAssertTrue(app.staticTexts["About this experiment"].waitForExistence(timeout: 5))
        tap("closeSheet", in: app)
        XCTAssertTrue(identified("learningPhase", in: app).waitForExistence(timeout: 5))
        returnHome(in: app)
        XCTAssertTrue(app.tabBars.buttons["Universe"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.state, .runningForeground, "The app must remain foreground after normal navigation and source-sheet dismissal.")
        attachScreenshot(named: "normal-homepage-after-navigation", in: app)
    }

    @MainActor
    private func launch(reset: Bool, application: XCUIApplication? = nil) -> XCUIApplication {
        continueAfterFailure = false
        let app = application ?? XCUIApplication()
        app.launchArguments = ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if reset { app.launchArguments.append("--reset-progress") }
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Universe"].waitForExistence(timeout: 15))
        selectTab("Universe", in: app)
        attachScreenshot(named: "homepage", in: app)
        return app
    }

    @MainActor
    private func selectTab(_ name: String, in app: XCUIApplication) {
        let tab = app.tabBars.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "Missing \(name) tab.")
        tab.tap()
    }

    @MainActor
    private func openLab(_ kind: String, in app: XCUIApplication) {
        let button = app.buttons["lab-\(kind)"]
        reveal(button, in: app)
        button.tap()
        XCTAssertTrue(identified("learningPhase", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(identified("resultValue", in: app).waitForExistence(timeout: 5))
        attachScreenshot(named: "\(kind)-stage", in: app)
    }

    @MainActor
    private func returnHome(in app: XCUIApplication) {
        let navigationButtons = app.navigationBars.buttons
        let back = navigationButtons.matching(
            NSPredicate(format: "identifier == %@ OR label == %@ OR label == %@ OR label == %@", "navigation-back", "Back", "Universe", "Sacred Universe")
        ).firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 5), "The experiment must have a native back button to Universe.")
        back.tap()
        expect(identified("learningPhase", in: app), predicate: NSPredicate(format: "exists == false"), message: "Back must leave the experiment.")
    }

    @MainActor
    private func tap(_ id: String, in app: XCUIApplication) {
        let button = app.buttons[id]
        reveal(button, in: app)
        XCTAssertTrue(button.isEnabled, "\(id) is disabled.")
        button.tap()
    }

    @MainActor
    private func identified(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    @MainActor
    private func result(in app: XCUIApplication) -> String {
        let readout = identified("resultValue", in: app)
        XCTAssertTrue(readout.waitForExistence(timeout: 5))
        return readout.label
    }

    @MainActor
    private func expectPhase(_ expected: String, in app: XCUIApplication) {
        let phase = identified("learningPhase", in: app)
        expect(phase, predicate: NSPredicate(format: "exists == true AND value == %@", expected), message: "Expected learning phase \(expected).")
    }

    @MainActor
    private func expectChangedResult(from previous: String, in app: XCUIApplication) {
        expect(identified("resultValue", in: app), predicate: NSPredicate(format: "exists == true AND label != %@ AND label != %@", previous, ""), message: "A parameter change must update the visible calculation.")
    }

    @MainActor
    private func expectResult(_ expected: String, in app: XCUIApplication) {
        expect(identified("resultValue", in: app), predicate: NSPredicate(format: "exists == true AND label == %@", expected), message: "The experiment's explored value must be retained.")
    }

    @MainActor
    private func expectNotebookCircle(in app: XCUIApplication) {
        let row = identified("discovery-circle", in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 5), "The saved circle insight must appear in Notebook.")
        let count = identified("notebookCount", in: app)
        XCTAssertTrue(count.waitForExistence(timeout: 5))
        XCTAssertTrue(count.label.hasPrefix("1"), "Saving one discovery must produce one Notebook entry.")
    }

    @MainActor
    private func innerNativeSwitch(_ id: String, in app: XCUIApplication) -> XCUIElement {
        let row = app.switches[id]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Missing sensory preference row \(id).")
        // A SwiftUI Form exposes the labelled Toggle row as a Switch and nests
        // the actual trailing native switch inside it. Tapping the row's center
        // misses that control, so tap and read the native descendant directly.
        let control = row.descendants(matching: .switch).firstMatch
        XCTAssertTrue(control.waitForExistence(timeout: 5), "Missing native switch inside \(id).")
        XCTAssertTrue(control.isHittable, "The native \(id) switch must be reachable.")
        return control
    }

    @MainActor
    private func expectSwitch(_ toggle: XCUIElement, value: String) {
        expect(toggle, predicate: NSPredicate(format: "exists == true AND value == %@", value), message: "Expected sensory preference value \(value).")
    }

    @MainActor
    private func expect(_ element: XCUIElement, predicate: NSPredicate, message: String) {
        let completion = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: 5)
        XCTAssertEqual(completion, .completed, message)
    }

    @MainActor
    private func attachScreenshot(named name: String, in app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        if element.exists && element.isHittable { return }
        let page = app.scrollViews.firstMatch
        XCTAssertTrue(page.waitForExistence(timeout: 5), "A scrollable page must expose offscreen controls.")
        for _ in 0..<12 {
            if element.exists && element.isHittable { return }
            page.swipeUp()
        }
        for _ in 0..<12 {
            if element.exists && element.isHittable { return }
            page.swipeDown()
        }
        XCTFail("Unable to reveal \(element.identifier).")
    }
}
