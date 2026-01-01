//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCMediaStream_ConvenienceTests: XCTestCase, @unchecked Sendable {

    func test_trackType_withScreenShareTrack() {
        let factory = PeerConnectionFactory.mock()
        let mediaStream = factory.mockMediaStream(streamID: "user123:TRACK_TYPE_SCREEN_SHARE")
        XCTAssertEqual(mediaStream.trackType, .screenshare)
    }

    func test_trackType_withVideoTrack() {
        let factory = PeerConnectionFactory.mock()
        let mediaStream = factory.mockMediaStream(streamID: "user123:TRACK_TYPE_VIDEO")
        XCTAssertEqual(mediaStream.trackType, .video)
    }

    func test_trackType_withAudioTrack() {
        let factory = PeerConnectionFactory.mock()
        let mediaStream = factory.mockMediaStream(streamID: "user123:TRACK_TYPE_AUDIO")
        XCTAssertEqual(mediaStream.trackType, .audio)
    }

    func test_trackType_withUnknownTrack() {
        let factory = PeerConnectionFactory.mock()
        let mediaStream = factory.mockMediaStream(streamID: "user123:TRACK_TYPE_UNKNOWN")
        XCTAssertEqual(mediaStream.trackType, .unknown)
    }

    func test_trackType_withInvalidStreamId() {
        let factory = PeerConnectionFactory.mock()
        let mediaStream = factory.mockMediaStream(streamID: "user123")
        XCTAssertEqual(mediaStream.trackType, .unknown)
    }

    func test_trackId_withValidStreamId() {
        let factory = PeerConnectionFactory.mock()
        let mediaStream = factory.mockMediaStream(streamID: "user123:TRACK_TYPE_VIDEO")
        XCTAssertEqual(mediaStream.trackId, "user123")
    }

    func test_trackId_withInvalidStreamId() {
        let factory = PeerConnectionFactory.mock()
        let mediaStream = factory.mockMediaStream(streamID: "user123")
        XCTAssertEqual(mediaStream.trackId, "user123")
    }
}
