//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

final class Authentication_Tests: StreamTestCase {
    
    let participants = 1
    let jwtExpirationTimeoutInSeconds = TestRunnerEnvironment.isCI ? "10" : "2"
    
    override func setUpWithError() throws {
        launchApp = false
        app.setLaunchArguments(.mockJwt)
        try super.setUpWithError()
    }
    
    override class func tearDown() {
        app.launch()
        userRobot.logout()
        sleep(1) // to make sure jwt mocking is turned off
        super.tearDown()
    }
    
    func waitForJwtToExpire() {
        sleep(UInt32(jwtExpirationTimeoutInSeconds)!)
    }
    
    func test_tokenExpiriesBeforeUserLogsIn() throws {
        linkToScenario(withId: 2562)
        
        GIVEN("token expires") {
            app.setLaunchArguments(.invalidateJwt)
            app.launch()
            waitForJwtToExpire()
        }
        WHEN("user logs in") {
            userRobot
                .logout()
                .login(waitForLoginPage: true)
                .startCall(callId)
        }
        THEN("app requests a token refresh") {}
        WHEN("participant joins the call") {
            participantRobot.joinCall(callId)
        }
        THEN("there are \(participants) participants on the call") {
            userRobot
                .waitForParticipantsToJoin(participants)
                .assertCallControls()
                .assertGridView(with: participants)
        }
    }
    
    func test_tokenExpiriesAfterUserLoggedIn() {
        linkToScenario(withId: 2563)

        GIVEN("user logs in") {
            app.setEnvironmentVariables([.jwtExpiration: jwtExpirationTimeoutInSeconds])
            app.launch()
            
            userRobot
                .logout()
                .login(waitForLoginPage: true)
                .startCall(callId)
        }
        WHEN("token expires") {}
        THEN("app requests a token refresh") {}
        WHEN("participant joins the call") {
            participantRobot.joinCall(callId)
        }
        THEN("there are \(participants) participants on the call") {
            userRobot
                .waitForParticipantsToJoin(participants)
                .assertCallControls()
                .assertGridView(with: participants)
        }
    }

    func test_tokenExpiriesWhenUserIsInBackground() {
        linkToScenario(withId: 2564)

        GIVEN("user logs in") {
            app.setEnvironmentVariables([.jwtExpiration: jwtExpirationTimeoutInSeconds])
            app.launch()
            
            userRobot
                .logout()
                .login(waitForLoginPage: true)
                .startCall(callId)
        }
        AND("user goes to background") {
            deviceRobot.moveApplication(to: .background)
        }
        AND("participant joins the call") {
            participantRobot.joinCall(callId)
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
                .logout()
                .login(waitForLoginPage: true)
                .startCall(callId, waitForCompletion: false)
        }
        WHEN("app requests a token refresh") {}
        THEN("app shows a connection error alert") {
            userRobot.assertConnectionErrorAlert()
        }
    }
}
