//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

// Requires running a standalone Sinatra server
final class DeeplinkTests: StreamTestCase {

    static override func setUp() {
        super.setUp()

        // We are launching and terminating the app to ensure the executable
        // has been installed.
        app.launch()
        app.terminate()
    }

    override func setUpWithError() throws {
        launchApp = false
        try super.setUpWithError()
    }

    private enum MockDeeplink {
        static let deeplinkUrl: URL = .init(string: "\(Sinatra().baseUrl)/deeplink?id=test-call")!
        static let deeplinkUrlWithCallIdInPath: URL = .init(string: "\(Sinatra().baseUrl)/deeplink/demos/join/test-call")!
        static let customScheme: URL = .init(string: "streamvideo://video/demos?id=test-call")!
        static let customSchemeWithCallIdInPath: URL = .init(string: "streamvideo://video/demos/join/test-call")!
    }

    func test_associationFile_validationWasSuccessful() throws {
        linkToScenario(withId: 2855)

        func assertEnvironment(_ environment: String) throws {
            let contentData = try Data(contentsOf: .init(string: environment)!)
            let content = try XCTUnwrap(String(data: contentData, encoding: .utf8))
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: " ", with: "")

            XCTAssertEqual(
                content,
                """
                {"applinks":{"apps":[],"details":[{"appID":"EHV7XZLAHA.io.getstream.iOS.VideoDemoApp","paths":["/video/demos/*","/video/demos"]}]}}
                """,
                "Associated file for \(environment) wasn't found."
            )
        }

        try [
            "https://getstream.io/.well-known/apple-app-site-association",
            "https://staging.getstream.io/.well-known/apple-app-site-association",
            "https://pronto.getstream.io/.well-known/apple-app-site-association",
        ].forEach { try assertEnvironment($0) }
    }

    func test_universalLink_production_joinsExpectedCall() {
        linkToScenario(withId: 2856)
        
        WHEN("user navigates to the app through deeplink") {
            Safari()
                .open(MockDeeplink.deeplinkUrl)
                .tapOnDeeplinkButton()
                .tapOnOpenButton()
        }
        THEN("user joins the the specified call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
    }

    func test_universalLink_deeplinkUrlWithCallIdInPath_joinsExpectedCall() {

        WHEN("user navigates to the app through deeplink") {
            Safari()
                .open(MockDeeplink.deeplinkUrlWithCallIdInPath)
                .tapOnDeeplinkButton()
                .tapOnOpenButton()
        }
        THEN("user joins the the specified call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
    }

    func test_customSchemeURL_joinsExpectedCall() {
        linkToScenario(withId: 2857)
        
        WHEN("user opens a URL that contains a custom scheme") {
            Safari()
                .open(MockDeeplink.customScheme)
                .tapOnOpenButton()
        }
        THEN("user joins the the specified call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
    }

    func test_customSchemeWithCallIdInPath_joinsExpectedCall() {
        WHEN("user opens a URL that contains a custom scheme") {
            Safari()
                .open(MockDeeplink.customSchemeWithCallIdInPath)
                .tapOnOpenButton()
        }
        THEN("user joins the the specified call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
    }
}
