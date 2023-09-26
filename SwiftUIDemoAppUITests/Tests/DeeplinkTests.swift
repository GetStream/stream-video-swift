//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

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
        static let production: URL = .init(string: "https://getstream.io/video/demos?id=test-call")!
        static let customScheme: URL = .init(string: "streamvideo://video/demos?id=test-call")!
    }

    func test_associationFile_validationWasSuccessful() throws {
        let contentData = try Data(contentsOf: .init(string: "https://getstream.io/.well-known/apple-app-site-association")!)
        let content = try XCTUnwrap(String(data: contentData, encoding: .utf8))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: " ", with: "")

        XCTAssertEqual(content, """
        {"applinks":{"apps":[],"details":[{"appID":"EHV7XZLAHA.io.getstream.iOS.VideoDemoApp","paths":["/video/demos/*","/video/demos"]}]}}
        """)
    }

    func test_universalLink_production_joinsExpectedCall() {
        WHEN("") {
            Safari.openUniversalLinkFromSmartBanner(MockDeeplink.production)
        }
        THEN("user joins the the specified call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
    }

    func test_customSchemeURL_joinsExpectedCall() {
        WHEN("User opens a URL that contains a custom scheme") {
            Safari.openApp(MockDeeplink.customScheme)
        }
        THEN("user joins the the specified call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
    }
}
