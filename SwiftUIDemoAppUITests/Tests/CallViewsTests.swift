//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import XCTest

final class CallViewsTests: StreamTestCase {
    
    func testUserIsAloneOnTheCall() {
        linkToScenario(withId: 1541)

        WHEN("user starts a new call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
        }
        THEN("user is alone on the call") {
            userRobot
                .assertCallControls()
                .assertEmptyCall()
        }
    }
    
    func testOneParticipantOnTheCall() throws {
        linkToScenario(withId: 1766)
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")
        
        let participants = 1

        WHEN("user starts a new call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
                .microphone(.disable)
        }
        WHEN("participants joins the call") {
            participantRobot
                .setUserCount(participants)
                .joinCall(callId, options: [.withCamera])
            userRobot.waitForParticipantsToJoin(participants)
        }
        AND("user enables grid view") {
            userRobot.setView(mode: .grid)
        }
        THEN("there are \(participants) participants on the call") {
            userRobot
                .assertCallControls()
                .assertGridView(with: participants)
        }
        WHEN("user enables spotlight view") {
            userRobot.setView(mode: .spotlight)
        }
        THEN("there are \(participants) participants on the call") {
            userRobot
                .assertCallControls()
                .assertSpotlightView(with: participants)
        }
        WHEN("user enables fullscreen view") {
            userRobot.setView(mode: .fullscreen)
        }
        THEN("there is only one participant visible in fullscreen view") {
            userRobot
                .assertCallControls()
                .assertFullscreenView()
        }
    }
    
    func testTwoParticipantsOnTheCall() throws {
        linkToScenario(withId: 1767)
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")

        let participants = 2

        WHEN("user starts a new call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
                .microphone(.disable)
        }
        WHEN("two participants join the call") {
            participantRobot
                .setUserCount(participants)
                .joinCall(callId, options: [.withCamera])
            userRobot.waitForParticipantsToJoin(participants)
        }
        AND("user enables grid view") {
            userRobot.setView(mode: .grid)
        }
        THEN("there are \(participants) participants on the call") {
            userRobot
                .assertCallControls()
                .assertGridView(with: participants)
        }
        WHEN("user enables spotlight view") {
            userRobot.setView(mode: .spotlight)
        }
        THEN("there are \(participants) participants on the call") {
            userRobot
                .assertCallControls()
                .assertSpotlightView(with: participants)
        }
        WHEN("user enables fullscreen view") {
            userRobot.setView(mode: .fullscreen)
        }
        THEN("there is only one participant visible in fullscreen view") {
            userRobot
                .assertCallControls()
                .assertFullscreenView()
        }
    }
    
    func testSwitchingBetweenViewsOnTheCall() throws {
        linkToScenario(withId: 1768)
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")
        
        let participants = 4

        WHEN("user starts a new call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
                .microphone(.disable)
        }
        WHEN("six participants joins the call") {
            let timeout = UserRobot.defaultTimeout * 3
            participantRobot
                .setUserCount(participants)
                .setCallDuration(timeout)
                .joinCall(callId, options: [.withCamera])
            userRobot.waitForParticipantsToJoin(participants)
        }
        AND("user enables grid view") {
            userRobot.setView(mode: .grid)
        }
        THEN("there are \(participants) participants on the call") {
            userRobot
                .assertCallControls()
                .assertGridView(with: participants)
        }
        WHEN("user enables spotlight view") {
            userRobot.setView(mode: .spotlight)
        }
        THEN("there are \(participants) participants on the call") {
            userRobot
                .assertCallControls()
                .assertSpotlightView(
                    with: participants -
                        1
                ) // We get one less due to the LazyHStack that initializes only a few items after the visible ones
        }
        WHEN("user enables fullscreen view") {
            userRobot.setView(mode: .fullscreen)
        }
        THEN("there is only one participant visible in fullscreen view") {
            userRobot
                .assertCallControls()
                .assertFullscreenView()
        }
    }
    
    func testUserMovesCornerDraggableView() throws {
        linkToScenario(withId: 1771)
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")
        
        let participants = 1
        
        GIVEN("user starts a call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
        }
        AND("participant joins the call") {
            participantRobot
                .setUserCount(participants)
                .joinCall(callId)
            userRobot.waitForParticipantsToJoin(participants)
        }
        WHEN("user enables grid view") {
            userRobot.setView(mode: .grid)
        }
        
        let initialCoordinates = CallPage.cornerDraggableView.centralCoordinates
        AND("user moves corner draggable view to the bottom right corner") {
            userRobot.moveCornerDraggableViewToTheBottom()
        }
        
        sleep(1) // wait for the view to settle
        let newCoordinates = CallPage.cornerDraggableView.centralCoordinates
        THEN("video view is in the bottom right corner") {
            XCTAssertEqual(initialCoordinates.x, newCoordinates.x)
            XCTAssertLessThan(initialCoordinates.y, newCoordinates.y)
        }
    }
    
    func testUserCanSeeAllParticipantsInScreenSharingView() throws {
        linkToScenario(withId: 1774)
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")
        
        let participants = 10
        
        GIVEN("user starts a call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
        }
        WHEN("ten participants join the call") {
            participantRobot
                .setUserCount(participants)
                .joinCall(callId, actions: [.shareScreen])
            userRobot.waitForParticipantsToJoin(participants, timeout: UserRobot.defaultTimeout * 1.5)
        }
        THEN("user observers participant's screen") {
            userRobot
                .assertParticipantStartSharingScreen()
        }
    }
    
    func testUserCanSeeAllParticipantsInGridView() throws {
        linkToScenario(withId: 1775)
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")
        
        let participants = 10
        
        GIVEN("user starts a call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
        }
        AND("ten participants join the call") {
            participantRobot
                .setUserCount(participants)
                .joinCall(callId)
            userRobot.waitForParticipantsToJoin(participants, timeout: UserRobot.defaultTimeout * 1.5)
        }
        WHEN("user enables grid view") {
            userRobot.setView(mode: .grid)
        }
        THEN("user observers the list of participants") {
            userRobot
                .assertGridView(with: participants)
                .assertGridViewParticipantListVisibity(percent: 0)
        }
        AND("user can scroll the list and see all participants") {
            userRobot
                .scrollGridViewParticipantList(to: .down, times: 2)
                .assertGridViewParticipantListVisibity(percent: 100)
        }
    }
    
    func testUserCanSeeAllParticipantsInSpotlightView() throws {
        linkToScenario(withId: 1776)
        
        try XCTSkipIf(TestRunnerEnvironment.isCI, "https://github.com/GetStream/ios-issues-tracking/issues/688")
        
        let participants = 10
        let expectedParticipantsInSpotlight = 3

        GIVEN("user starts a call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
        }
        AND("ten participants join the call") {
            participantRobot
                .setUserCount(participants)
                .joinCall(callId)
            userRobot.waitForParticipantsToJoin(participants, timeout: UserRobot.defaultTimeout * 1.5)
        }
        WHEN("user enables spotlight view") {
            userRobot.setView(mode: .spotlight)
        }
        THEN("user observes the list of participants") {
            userRobot
                .assertSpotlightView(with: expectedParticipantsInSpotlight)
        }
    }
    
    func testMicrophoneIcon() throws {
        linkToScenario(withId: 1777)
        
        GIVEN("user starts a call") {
            userRobot
                .waitForAutoLogin()
                .startCall(callId)
        }
        WHEN("user unmutes themselves - or if already enabled do nothing") {
            userRobot.microphone(.enable)
        }
        THEN("mic icon updates - should be enabled") {
            userRobot.assertUserMicrophoneIsEnabled()
        }
        WHEN("user mutes themselves") {
            userRobot.microphone(.disable)
        }
        THEN("mic icon updates - should be disabled") {
            userRobot.assertUserMicrophoneIsDisabled()
        }
    }
}
