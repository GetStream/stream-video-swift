//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class SFUMiddleware_Tests: XCTestCase, @unchecked Sendable {

//    private var mockSFUService: MockSignalServer!
//    private var mockSFUAdapter: SFUAdapter!
//
//    private lazy var sessionID: String! = .unique
//    private lazy var peerConnectionFactory: PeerConnectionFactory! = .init(
//        audioProcessingModule: MockAudioProcessingModule()
//    )
//    private lazy var subject: SfuMiddleware! = .init(
//        sessionID: sessionID,
//        user: .dummy(),
//        state: .init(),
//        participantThreshold: 25
//    )
//
//    override func setUp() {
//        super.setUp()
//        let mockSFUStack = SFUAdapter.mock(webSocketClientType: .sfu)
//        mockSFUAdapter = mockSFUStack.sfuAdapter
//        mockSFUService = mockSFUStack.mockService
//
//        subject.sfuAdapter = mockSFUAdapter
//    }
//
//    override func tearDown() {
//        peerConnectionFactory = nil
//        sessionID = nil
//        mockSFUAdapter = nil
//        mockSFUService = nil
//        subject.update(publisher: nil)
//        subject.update(subscriber: nil)
//        subject = nil
//        super.tearDown()
//    }
//
//    // MARK: - handleEvent
//
//    @MainActor
//    func test_handleEvent_SubscriberOffer_sendAnswerWasCalledOnSFUAdapter() async throws {
//        let peerConnection: PeerConnection = try .dummy(
//            peerConnectionFactory,
//            sessionID: sessionID,
//            peerConnectionType: .subscriber,
//            sfuAdapter: mockSFUAdapter
//        )
//        // We are pausing here as ICE trickle during testing produces an error
//        peerConnection.paused = true
//        subject.update(
//            subscriber: peerConnection
//        )
//
//        var payload = Stream_Video_Sfu_Event_SubscriberOffer()
//        payload
//            .sdp =
//            "v=0\r\no=- 6253277588121781340 1722620346 IN IP4 0.0.0.0\r\ns=-\r\nt=0 0\r\na=msid-semantic:WMS*\r\na=fingerprint:sha-256 73:B2:51:37:1E:25:FB:DD:3D:C2:2B:B9:45:0C:4E:3C:75:B0:CB:4C:BD:4C:56:3E:60:8D:DB:C5:D6:94:09:48\r\na=ice-lite\r\na=extmap-allow-mixed\r\na=group:BUNDLE 0\r\nm=video 9 UDP/TLS/RTP/SAVPF 96 125 108 123\r\nc=IN IP4 0.0.0.0\r\na=setup:actpass\r\na=mid:0\r\na=ice-ufrag:wKDYzjQawwtpAMbt\r\na=ice-pwd:PuzKCfmOGKSZBqsmkGVuCNlniElJGNtK\r\na=rtcp-mux\r\na=rtcp-rsize\r\na=rtpmap:96 VP8/90000\r\na=rtcp-fb:96 ccm fir\r\na=rtcp-fb:96 nack \r\na=rtcp-fb:96 nack pli\r\na=rtcp-fb:96 goog-remb \r\na=rtpmap:125 H264/90000\r\na=fmtp:125 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01f\r\na=rtcp-fb:125 ccm fir\r\na=rtcp-fb:125 nack \r\na=rtcp-fb:125 nack pli\r\na=rtcp-fb:125 goog-remb \r\na=rtpmap:108 H264/90000\r\na=fmtp:108 level-asymmetry-allowed=1;packetization-mode=0;profile-level-id=42e01f\r\na=rtcp-fb:108 ccm fir\r\na=rtcp-fb:108 nack \r\na=rtcp-fb:108 nack pli\r\na=rtcp-fb:108 goog-remb \r\na=rtpmap:123 H264/90000\r\na=fmtp:123 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=640032\r\na=rtcp-fb:123 ccm fir\r\na=rtcp-fb:123 nack \r\na=rtcp-fb:123 nack pli\r\na=rtcp-fb:123 goog-remb \r\na=extmap:1 https://aomediacodec.github.io/av1-rtp-spec/#dependency-descriptor-rtp-header-extension\r\na=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time\r\na=ssrc:3952328987 cname:093d57597b6772a7:TRACK_TYPE_VIDEO\r\na=ssrc:3952328987 msid:093d57597b6772a7:TRACK_TYPE_VIDEO fb9005c3-36ac-4946-99c1-d2e8e374ea77\r\na=ssrc:3952328987 mslabel:093d57597b6772a7:TRACK_TYPE_VIDEO\r\na=ssrc:3952328987 label:fb9005c3-36ac-4946-99c1-d2e8e374ea77\r\na=msid:093d57597b6772a7:TRACK_TYPE_VIDEO fb9005c3-36ac-4946-99c1-d2e8e374ea77\r\na=sendrecv\r\n"
//
//        _ = subject.handle(event: .sfuEvent(.subscriberOffer(payload)))
//
//        await fulfillment { self.mockSFUService.sendAnswerWasCalledWithRequest != nil }
//
//        let request = try XCTUnwrap(mockSFUService.sendAnswerWasCalledWithRequest)
//        XCTAssertEqual(request.sessionID, sessionID)
//        XCTAssertEqual(request.peerType, .subscriber)
//        XCTAssertTrue(!request.sdp.isEmpty)
//
//        peerConnection.close()
//    }
}

// extension PeerConnection {
//
//    static func dummy(
//        _ factory: PeerConnectionFactory,
//        sessionID: String,
//        peerConnectionType: PeerConnectionType,
//        sfuAdapter: SFUAdapter,
//        videoOptions: VideoOptions = .init()
//    ) throws -> PeerConnection {
//        try factory.makePeerConnection(
//            sessionId: sessionID,
//            configuration: .makeConfiguration(with: []),
//            type: peerConnectionType,
//            sfuAdapter: sfuAdapter,
//            videoOptions: videoOptions
//        )
//    }
// }
