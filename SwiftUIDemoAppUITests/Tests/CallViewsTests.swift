//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

final class CallViewsTests: StreamTestCase {
    
    func testUserIsAloneOnTheCall() {
        linkToScenario(withId: 1541)

        WHEN("user starts a new call") {
            userRobot.login().startCall(callId)
        }
        THEN("user is alone on the call") {
            userRobot
                .assertCallControls()
                .assertEmptyCall()
        }
    }
    
    func testOneParticipantOnTheCall() {
        linkToScenario(withId: 1766)
        
        let participants = 1

        WHEN("user starts a new call") {
            userRobot
                .login()
                .startCall(callId)
                .microphone(.disable)
        }
        WHEN("participants joins the call") {
            participantRobot
                .setUserCount(participants)
                .joinCall(callId, options: [.withCamera])
        }
        AND("user enables grid view") {
            userRobot.setView(mode: .grid)
        }
        THEN("there are \(participants) participants on the call") {
            userRobot
                .waitForParticipantsToJoin(participants)
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
    
    func testTwoParticipantsOnTheCall() {
        linkToScenario(withId: 1767)
        
        let participants = 2

        WHEN("user starts a new call") {
            userRobot
                .login()
                .startCall(callId)
                .microphone(.disable)
        }
        WHEN("two participants joins the call") {
            participantRobot
                .setUserCount(participants)
                .joinCall(callId, options: [.withCamera])
        }
        AND("user enables grid view") {
            userRobot.setView(mode: .grid)
        }
        THEN("there are \(participants) participants on the call") {
            userRobot
                .waitForParticipantsToJoin(participants)
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
    
    func testSwitchingBetweenViewsOnTheCall() {
        linkToScenario(withId: 1768)
        
        let participants = 4

        WHEN("user starts a new call") {
            userRobot
                .login()
                .startCall(callId)
                .microphone(.disable)
        }
        WHEN("six participants joins the call") {
            let timeout = UserRobot.defaultTimeout * 3
            participantRobot
                .setUserCount(participants)
                .setCallDuration(timeout)
                .joinCall(callId, options: [.withCamera])
        }
        AND("user enables grid view") {
            userRobot.setView(mode: .grid)
        }
        THEN("there are \(participants) participants on the call") {
            userRobot
                .waitForParticipantsToJoin(participants)
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
    
    func testUserShrinksVideoView() {
        linkToScenario(withId: 1770)
        
        let participants = 2
        
        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        AND("participants join the call") {
            participantRobot
                .setUserCount(participants)
                .joinCall(callId)
        }
        WHEN("user enables grid view") {
            userRobot.setView(mode: .grid)
        }
        AND("user minimizes video view") {
            userRobot
                .waitForParticipantsToJoin(participants)
                .minimizeVideoView()
        }
        THEN("video view is minimized for the user") {
            userRobot
                .assertThereAreNoCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
        WHEN("user maximizes video view") {
            userRobot.maximizeVideoView()
        }
        THEN("video view is maximized for the user") {
            userRobot
                .assertCallControls()
                .assertGridView(with: participants)
        }
        WHEN("user enables spotlight view") {
            userRobot.setView(mode: .spotlight)
        }
        AND("user minimizes video view") {
            userRobot.minimizeVideoView()
        }
        THEN("video view is minimized for the user") {
            userRobot
                .assertThereAreNoCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
        WHEN("user maximizes video view") {
            userRobot.maximizeVideoView()
        }
        THEN("video view is maximized for the user") {
            userRobot
                .assertCallControls()
                .assertSpotlightView(with: participants)
        }
        WHEN("user enables fullscreen view") {
            userRobot.setView(mode: .fullscreen)
        }
        AND("user minimizes video view") {
            userRobot.minimizeVideoView()
        }
        THEN("video view is minimized for the user") {
            userRobot
                .assertThereAreNoCallControls()
                .assertParticipantsAreVisible(count: 1)
        }
        WHEN("user maximizes video view") {
            userRobot.maximizeVideoView()
        }
        THEN("video view is maximized for the user") {
            userRobot
                .assertCallControls()
                .assertFullscreenView()
        }
    }
    
    func testUserMovesCornerDragableView() {
        linkToScenario(withId: 1771)
        
        let participants = 1
        
        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        AND("participant joins the call") {
            participantRobot
                .setUserCount(participants)
                .joinCall(callId)
        }
        WHEN("user enables grid view") {
            userRobot.setView(mode: .grid)
        }
        
        let initialCoordinates = CallPage.cornerDragableView.centralCoordinates
        AND("user moves corner dragable view to the bottom right corner") {
            userRobot.moveCornerDragableViewToTheBottom()
        }
        
        sleep(1) // wait for the view to settle
        let newCoordinates = CallPage.cornerDragableView.centralCoordinates
        THEN("video view is in the bottom right corner") {
            XCTAssertEqual(initialCoordinates.x, newCoordinates.x)
            XCTAssertLessThan(initialCoordinates.y, newCoordinates.y)
        }
    }
    
    func testUserMovesMinimizedVideoView() {
        linkToScenario(withId: 1772)
        
        let participants = 1
        
        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        AND("participant joins the call") {
            participantRobot
                .setUserCount(participants)
                .joinCall(callId)
        }
        WHEN("user minimizes video view") {
            userRobot.minimizeVideoView()
        }
        
        let initialCoordinates = CallPage.minimizedCallView.centralCoordinates
        AND("user moves minimized call view to the bottom right corner") {
            userRobot.moveMinimizedCallViewToTheLeft()
        }
        
        sleep(1) // wait for the view to settle
        let newCoordinates = CallPage.minimizedCallView.centralCoordinates
        THEN("video view is in the top left corner") {
            XCTAssertLessThan(newCoordinates.x, initialCoordinates.x)
        }
    }
    
    func testUserCanSeeAllParticipantsInScreenSharingView() {
        linkToScenario(withId: 1774)
        
        let participants = 10
        
        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        WHEN("ten participants join the call") {
            participantRobot
                .setUserCount(participants)
                .joinCall(callId, actions: [.shareScreen])
        }
        THEN("user observers participant's screen") {
            userRobot
                .waitForParticipantsToJoin(participants)
                .assertParticipantStartSharingScreen()
                .assertScreenSharingParticipantListVisibity(percent: 0)
        }
        AND("user can scroll and see all participants") {
            userRobot
                .scrollScreenSharingParticipantList(to: .right, times: 2)
                .assertScreenSharingParticipantListVisibity(percent: 100)
        }
    }
    
    func testUserCanSeeAllParticipantsInGridView() {
        linkToScenario(withId: 1775)
        
        let participants = 10
        
        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        AND("ten participants join the call") {
            participantRobot
                .setUserCount(participants)
                .joinCall(callId)
        }
        WHEN("user enables grid view") {
            userRobot.setView(mode: .grid)
        }
        THEN("user observers the list of participants") {
            userRobot
                .waitForParticipantsToJoin(participants)
                .assertGridView(with: participants)
                .assertGridViewParticipantListVisibity(percent: 0)
        }
        AND("user can scroll the list and see all participants") {
            userRobot
                .scrollGridViewParticipantList(to: .down, times: 2)
                .assertGridViewParticipantListVisibity(percent: 100)
        }
    }
    
    func testUserCanSeeAllParticipantsInSpotlightView() {
        linkToScenario(withId: 1776)
        
        let participants = 10
        
        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        AND("ten participants join the call") {
            participantRobot
                .setUserCount(participants)
                .joinCall(callId)
        }
        WHEN("user enables spotlight view") {
            userRobot.setView(mode: .spotlight)
        }
        THEN("user observers the list of participants") {
            userRobot
                .waitForParticipantsToJoin(participants)
                .assertSpotlightView(with: participants)
                .assertSpotlightViewParticipantListVisibity(percent: 0)
        }
        AND("user can scroll the list and see all participants") {
            userRobot
                .scrollSpotlightParticipantList(to: .right, times: 2)
                .assertSpotlightViewParticipantListVisibity(percent: 100)
        }
    }
    
    func testMicrophoneIcon() {
        linkToScenario(withId: 1777)
        
        GIVEN("user starts a call") {
            userRobot.login().startCall(callId)
        }
        WHEN("user unmutes themselves") {
            userRobot.microphone(.enable)
        }
        THEN("mic icon updates") {
            userRobot.assertUserMicrophoneIsEnabled()
        }
        WHEN("user mutes themselves") {
            userRobot.microphone(.disable)
        }
        THEN("mic icon updates") {
            userRobot.assertUserMicrophoneIsDisabled()
        }
    }
}
