//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

// Requires running a standalone Sinatra server
final class DeeplinkTests: StreamTestCase {

    private enum MockDeeplink {
        static let deeplinkUrlWithCallIdInPath: URL = .init(string: "https://getstream.io/video/demos/join/test-call")!
        static let customScheme: URL = .init(string: "streamvideo://video/demos?id=test-call")!
        static let customSchemeWithCallIdInPath: URL = .init(string: "streamvideo://video/demos/join/test-call")!

        static func customScheme(callId: String) -> URL {
            .init(string: "streamvideo://video/demos?id=\(callId)")!
        }
    }

    func test_associationFile_validationWasSuccessful() throws {
        linkToScenario(withId: 2855)

        func assertEnvironment(_ environment: String) throws {
            let contentData = try Data(contentsOf: .init(string: environment)!)
            let content = try XCTUnwrap(String(data: contentData, encoding: .utf8))
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: " ", with: "")

            let prodAndStaging = """
            {"applinks":{"apps":[],"details":[{"appIDs":["EHV7XZLAHA.io.getstream.iOS.VideoDemoApp","EHV7XZLAHA.io.getstream.rnvideosample"],"paths":["/video/demos/*","/video/demos"]}]}}
            """
            let pronto = """
            {"applinks":{"apps":[],"details":[{"appIDs":["EHV7XZLAHA.io.getstream.iOS.VideoDemoApp","EHV7XZLAHA.io.getstream.iOS.stream-calls-dogfood","EHV7XZLAHA.io.getstream.rnvideosample","EHV7XZLAHA.io.getstream.video.flutter.dogfooding"],"paths":["*"]}]}}
            """

            let expected = environment.hasPrefix("https://pronto") ? pronto : prodAndStaging

            XCTAssertEqual(content, expected, "Associated file for \(environment) wasn't found.")
        }

        try [
            "https://getstream.io/.well-known/apple-app-site-association",
            "https://staging.getstream.io/.well-known/apple-app-site-association",
            "https://pronto.getstream.io/.well-known/apple-app-site-association"
        ].forEach { try assertEnvironment($0) }
    }

    func test_universalLink_deeplinkUrlWithCallIdInPath_joinsExpectedCall() throws {
        throw XCTSkip("https://github.com/GetStream/ios-issues-tracking/issues/764")

        linkToScenario(withId: 2954)

        WHEN("user navigates to the app through deeplink") {
            openURL(MockDeeplink.deeplinkUrlWithCallIdInPath)
        }
        THEN("user joins the the specified call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
    }

    func test_customSchemeURL_joinsExpectedCall() throws {
        linkToScenario(withId: 2857)
        
        WHEN("user opens a URL that contains a custom scheme") {
            openURL(MockDeeplink.customScheme)
        }
        THEN("user joins the the specified call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
    }

    func test_customSchemeWithCallIdInPath_joinsExpectedCall() throws {
        linkToScenario(withId: 2955)
        
        WHEN("user opens a URL that contains a custom scheme") {
            openURL(MockDeeplink.customSchemeWithCallIdInPath)
        }
        THEN("user joins the the specified call") {
            userRobot
                .assertCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
    }

    func test_customSchemeURL_forActiveCall_doesNotRejoinAfterLeaving() throws {
        GIVEN("user starts the call referenced by the deeplink") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
        }
        WHEN("user opens a deeplink for the active call") {
            openURL(MockDeeplink.customScheme(callId: callId))
        }
        AND("user leaves the call") {
            userRobot.endCall()
        }
        THEN("user stays out of the call") {
            userRobot.assertThereAreNoCallControls()
            XCTAssertTrue(
                CallDetailsPage.callIdInputField.wait().exists,
                "callIdInputField should appear"
            )

            let rejoinExpectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == true"),
                object: CallPage.hangUpButton
            )
            rejoinExpectation.isInverted = true

            XCTAssertEqual(
                XCTWaiter.wait(for: [rejoinExpectation], timeout: 3),
                .completed
            )
        }
    }
}
