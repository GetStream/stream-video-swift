//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreGraphics
@testable import StreamVideo
import XCTest

final class StreamVideoSfuSignalTrackSubscriptionDetails_ConvenienceTests: XCTestCase, @unchecked Sendable {

    func test_initWithVideoTrack() {
        let userId = "user123"
        let sessionId = "session123"
        let size = CGSize(width: 1920, height: 1080)
        let type = Stream_Video_Sfu_Models_TrackType.video

        let trackSubscriptionDetails = Stream_Video_Sfu_Signal_TrackSubscriptionDetails(
            for: userId,
            sessionId: sessionId,
            size: size,
            type: type
        )

        XCTAssertEqual(trackSubscriptionDetails.userID, userId)
        XCTAssertEqual(trackSubscriptionDetails.sessionID, sessionId)
        XCTAssertEqual(trackSubscriptionDetails.trackType, type)
        XCTAssertEqual(trackSubscriptionDetails.dimension.width, 1920)
        XCTAssertEqual(trackSubscriptionDetails.dimension.height, 1080)
    }

    func test_initWithScreenShareTrack() {
        let userId = "user123"
        let sessionId = "session123"
        let size = CGSize(width: 1280, height: 720)
        let type = Stream_Video_Sfu_Models_TrackType.screenShare

        let trackSubscriptionDetails = Stream_Video_Sfu_Signal_TrackSubscriptionDetails(
            for: userId,
            sessionId: sessionId,
            size: size,
            type: type
        )

        XCTAssertEqual(trackSubscriptionDetails.userID, userId)
        XCTAssertEqual(trackSubscriptionDetails.sessionID, sessionId)
        XCTAssertEqual(trackSubscriptionDetails.trackType, type)
        XCTAssertEqual(trackSubscriptionDetails.dimension.width, 1280)
        XCTAssertEqual(trackSubscriptionDetails.dimension.height, 720)
    }

    func test_initWithAudioTrack() {
        let userId = "user123"
        let sessionId = "session123"
        let type = Stream_Video_Sfu_Models_TrackType.audio

        let trackSubscriptionDetails = Stream_Video_Sfu_Signal_TrackSubscriptionDetails(
            for: userId,
            sessionId: sessionId,
            type: type
        )

        XCTAssertEqual(trackSubscriptionDetails.userID, userId)
        XCTAssertEqual(trackSubscriptionDetails.sessionID, sessionId)
        XCTAssertEqual(trackSubscriptionDetails.trackType, type)
        XCTAssertEqual(trackSubscriptionDetails.dimension.width, 0)
        XCTAssertEqual(trackSubscriptionDetails.dimension.height, 0)
    }

    func test_initWithNilSize() {
        let userId = "user123"
        let sessionId = "session123"
        let type = Stream_Video_Sfu_Models_TrackType.video

        let trackSubscriptionDetails = Stream_Video_Sfu_Signal_TrackSubscriptionDetails(
            for: userId,
            sessionId: sessionId,
            size: nil,
            type: type
        )

        XCTAssertEqual(trackSubscriptionDetails.userID, userId)
        XCTAssertEqual(trackSubscriptionDetails.sessionID, sessionId)
        XCTAssertEqual(trackSubscriptionDetails.trackType, type)
        XCTAssertEqual(trackSubscriptionDetails.dimension.width, 0)
        XCTAssertEqual(trackSubscriptionDetails.dimension.height, 0)
    }
}
