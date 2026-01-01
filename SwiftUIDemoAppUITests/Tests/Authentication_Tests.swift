//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

final class Authentication_Tests: StreamTestCase {
    
    let participants = 1
    let jwtExpirationTimeoutInSeconds = TestRunnerEnvironment.isCI ? "20" : "10"

    override func setUpWithError() throws {
        launchApp = false
        app.setLaunchArguments(.mockJwt)
        try super.setUpWithError()
    }
    
    func waitForJwtToExpire() {
        Thread.sleep(forTimeInterval: TimeInterval(jwtExpirationTimeoutInSeconds)!)
    }
    
    func test_tokenExpiresBeforeUserLogsIn() throws {
        linkToScenario(withId: 2562)
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")
        
        GIVEN("token expires") {
            app.setLaunchArguments(.invalidateJwt)
            app.launch()
        }
        WHEN("user logs in") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
                .waitCallControllsToAppear()
        }
        THEN("app requests a token refresh") {}
        WHEN("participant joins the call") {
            participantRobot
                .joinCall(callId)
        }
        THEN("there are \(participants) participants on the call") {
            userRobot
                .waitForParticipantsToJoin(participants)
                .assertGridView(with: participants)
        }
    }
    
    func test_tokenExpiresAfterUserLoggedIn() throws {
        linkToScenario(withId: 2563)
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")

        GIVEN("user logs in") {
            app.setEnvironmentVariables([.jwtExpiration: jwtExpirationTimeoutInSeconds])
            app.launch()
            
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
                .waitCallControllsToAppear()
        }
        WHEN("token expires") {
            waitForJwtToExpire()
        }
        THEN("app requests a token refresh") {}
        WHEN("participant joins the call") {
            participantRobot
                .joinCall(callId)
        }
        THEN("there are \(participants) participants on the call") {
            userRobot
                .waitForParticipantsToJoin(participants)
                .assertGridView(with: participants)
        }
    }

    func test_tokenExpiresWhenUserIsInBackground() throws {
        linkToScenario(withId: 2564)
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")

        GIVEN("user logs in") {
            app.setEnvironmentVariables([.jwtExpiration: jwtExpirationTimeoutInSeconds])
            app.launch()
            
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
                .waitCallControllsToAppear()
        }
        AND("user goes to background") {
            deviceRobot.moveApplication(to: .background)
        }
        AND("participant joins the call") {
            participantRobot
                .joinCall(callId)
        }
        WHEN("token expires") {
            waitForJwtToExpire()
        }
        AND("user comes back to foreground") {
            deviceRobot.moveApplication(to: .foreground)
        }
        THEN("there are \(participants) participants on the call") {
            userRobot
                .waitForParticipantsToJoin(participants)
                .assertCallControls()
                .assertGridView(with: participants)
        }
    }

    func test_tokenGenerationFails() {
        linkToScenario(withId: 2566)

        GIVEN("JWT generation breaks on server side") {
            app.setLaunchArguments(.breakJwt)
            app.launch()
        }
        AND("user tries to log in") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId, waitForCompletion: false)
        }
        WHEN("app requests a token refresh") {}
        THEN("app shows a connection error alert") {
            userRobot.assertConnectionErrorAlert()
        }
    }
}
