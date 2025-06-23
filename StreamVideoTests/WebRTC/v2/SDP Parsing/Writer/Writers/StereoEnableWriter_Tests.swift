//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class StereoEnableWriter_Tests: XCTestCase, @unchecked Sendable {

    private lazy var data: [String: MidStereoInformation]! = [:]
    private lazy var subject: StereoEnableWriter! = .init(data)

    override func tearDown() {
        subject = nil
        data = nil
        super.tearDown()
    }

    // MARK: - visit(line:)

    func test_visit_oneMidOneEnabled_withValidMediaLines() throws {
        data = ["0": .init(mid: "0", codecPayload: "111", isStereoEnabled: true)]
        _ = subject
        let expected = [
            "m=audio 9 UDP/TLS/RTP/SAVPF 111 63",
            "c=IN IP4 0.0.0.0",
            "a=rtcp:9 IN IP4 0.0.0.0",
            "a=ice-ufrag:zcgT",
            "a=ice-pwd:v559SXDwx4y9yAv7oeCvjsDR",
            "a=ice-options:trickle",
            "a=fingerprint:sha-256 F7:C8:B3:87:4A:AD:5A:86:48:1B:51:04:BE:CE:3B:D6:D3:7C:25:63:3E:9C:2B:F6:5B:8C:65:1F:72:8A:11:61",
            "a=setup:active",
            "a=mid:0",
            "a=recvonly",
            "a=rtcp-mux",
            "a=rtcp-rsize",
            "a=rtpmap:111 opus/48000/2",
            "a=fmtp:111 minptime=10;useinbandfec=1;stereo=1"
        ]

        let actual = [
            "m=audio 9 UDP/TLS/RTP/SAVPF 111 63",
            "c=IN IP4 0.0.0.0",
            "a=rtcp:9 IN IP4 0.0.0.0",
            "a=ice-ufrag:zcgT",
            "a=ice-pwd:v559SXDwx4y9yAv7oeCvjsDR",
            "a=ice-options:trickle",
            "a=fingerprint:sha-256 F7:C8:B3:87:4A:AD:5A:86:48:1B:51:04:BE:CE:3B:D6:D3:7C:25:63:3E:9C:2B:F6:5B:8C:65:1F:72:8A:11:61",
            "a=setup:active",
            "a=mid:0",
            "a=recvonly",
            "a=rtcp-mux",
            "a=rtcp-rsize",
            "a=rtpmap:111 opus/48000/2",
            "a=fmtp:111 minptime=10;useinbandfec=1"
        ]
        .map { subject.visit(line: $0) }

        XCTAssertEqual(actual, expected)
    }

    func test_visit_moreThanOneMidMoreThanOneEnabled_withValidMediaLines() throws {
        data = [
            "0": .init(mid: "0", codecPayload: "111", isStereoEnabled: true),
            "1": .init(mid: "1", codecPayload: "112", isStereoEnabled: true)
        ]
        _ = subject
        let expected = [
            "m=audio 9 UDP/TLS/RTP/SAVPF 111 63",
            "c=IN IP4 0.0.0.0",
            "a=rtcp:9 IN IP4 0.0.0.0",
            "a=ice-ufrag:zcgT",
            "a=ice-pwd:v559SXDwx4y9yAv7oeCvjsDR",
            "a=ice-options:trickle",
            "a=fingerprint:sha-256 F7:C8:B3:87:4A:AD:5A:86:48:1B:51:04:BE:CE:3B:D6:D3:7C:25:63:3E:9C:2B:F6:5B:8C:65:1F:72:8A:11:61",
            "a=setup:active",
            "a=mid:0",
            "a=recvonly",
            "a=rtcp-mux",
            "a=rtcp-rsize",
            "a=rtpmap:111 opus/48000/2",
            "a=fmtp:111 minptime=10;useinbandfec=1;stereo=1",
            
            "m=audio 9 UDP/TLS/RTP/SAVPF 111 63",
            "c=IN IP4 0.0.0.0",
            "a=rtcp:9 IN IP4 0.0.0.0",
            "a=ice-ufrag:zcgT",
            "a=ice-pwd:v559SXDwx4y9yAv7oeCvjsDR",
            "a=ice-options:trickle",
            "a=fingerprint:sha-256 F7:C8:B3:87:4A:AD:5A:86:48:1B:51:04:BE:CE:3B:D6:D3:7C:25:63:3E:9C:2B:F6:5B:8C:65:1F:72:8A:11:61",
            "a=setup:active",
            "a=mid:1",
            "a=recvonly",
            "a=rtcp-mux",
            "a=rtcp-rsize",
            "a=rtpmap:112 opus/48000/2",
            "a=fmtp:112 minptime=10;useinbandfec=1;stereo=1"
        ]

        let actual = [
            "m=audio 9 UDP/TLS/RTP/SAVPF 111 63",
            "c=IN IP4 0.0.0.0",
            "a=rtcp:9 IN IP4 0.0.0.0",
            "a=ice-ufrag:zcgT",
            "a=ice-pwd:v559SXDwx4y9yAv7oeCvjsDR",
            "a=ice-options:trickle",
            "a=fingerprint:sha-256 F7:C8:B3:87:4A:AD:5A:86:48:1B:51:04:BE:CE:3B:D6:D3:7C:25:63:3E:9C:2B:F6:5B:8C:65:1F:72:8A:11:61",
            "a=setup:active",
            "a=mid:0",
            "a=recvonly",
            "a=rtcp-mux",
            "a=rtcp-rsize",
            "a=rtpmap:111 opus/48000/2",
            "a=fmtp:111 minptime=10;useinbandfec=1",
            
            "m=audio 9 UDP/TLS/RTP/SAVPF 111 63",
            "c=IN IP4 0.0.0.0",
            "a=rtcp:9 IN IP4 0.0.0.0",
            "a=ice-ufrag:zcgT",
            "a=ice-pwd:v559SXDwx4y9yAv7oeCvjsDR",
            "a=ice-options:trickle",
            "a=fingerprint:sha-256 F7:C8:B3:87:4A:AD:5A:86:48:1B:51:04:BE:CE:3B:D6:D3:7C:25:63:3E:9C:2B:F6:5B:8C:65:1F:72:8A:11:61",
            "a=setup:active",
            "a=mid:1",
            "a=recvonly",
            "a=rtcp-mux",
            "a=rtcp-rsize",
            "a=rtpmap:112 opus/48000/2",
            "a=fmtp:112 minptime=10;useinbandfec=1"
        ]
        .map { subject.visit(line: $0) }

        XCTAssertEqual(actual, expected)
    }

    func test_visit_moreThanOneMidOneEnabled_withValidMediaLines() throws {
        data = [
            "1": .init(mid: "1", codecPayload: "112", isStereoEnabled: true)
        ]
        _ = subject
        let expected = [
            "m=audio 9 UDP/TLS/RTP/SAVPF 111 63",
            "c=IN IP4 0.0.0.0",
            "a=rtcp:9 IN IP4 0.0.0.0",
            "a=ice-ufrag:zcgT",
            "a=ice-pwd:v559SXDwx4y9yAv7oeCvjsDR",
            "a=ice-options:trickle",
            "a=fingerprint:sha-256 F7:C8:B3:87:4A:AD:5A:86:48:1B:51:04:BE:CE:3B:D6:D3:7C:25:63:3E:9C:2B:F6:5B:8C:65:1F:72:8A:11:61",
            "a=setup:active",
            "a=mid:0",
            "a=recvonly",
            "a=rtcp-mux",
            "a=rtcp-rsize",
            "a=rtpmap:111 opus/48000/2",
            "a=fmtp:111 minptime=10;useinbandfec=1",
            
            "m=audio 9 UDP/TLS/RTP/SAVPF 111 63",
            "c=IN IP4 0.0.0.0",
            "a=rtcp:9 IN IP4 0.0.0.0",
            "a=ice-ufrag:zcgT",
            "a=ice-pwd:v559SXDwx4y9yAv7oeCvjsDR",
            "a=ice-options:trickle",
            "a=fingerprint:sha-256 F7:C8:B3:87:4A:AD:5A:86:48:1B:51:04:BE:CE:3B:D6:D3:7C:25:63:3E:9C:2B:F6:5B:8C:65:1F:72:8A:11:61",
            "a=setup:active",
            "a=mid:1",
            "a=recvonly",
            "a=rtcp-mux",
            "a=rtcp-rsize",
            "a=rtpmap:112 opus/48000/2",
            "a=fmtp:112 minptime=10;useinbandfec=1;stereo=1"
        ]

        let actual = [
            "m=audio 9 UDP/TLS/RTP/SAVPF 111 63",
            "c=IN IP4 0.0.0.0",
            "a=rtcp:9 IN IP4 0.0.0.0",
            "a=ice-ufrag:zcgT",
            "a=ice-pwd:v559SXDwx4y9yAv7oeCvjsDR",
            "a=ice-options:trickle",
            "a=fingerprint:sha-256 F7:C8:B3:87:4A:AD:5A:86:48:1B:51:04:BE:CE:3B:D6:D3:7C:25:63:3E:9C:2B:F6:5B:8C:65:1F:72:8A:11:61",
            "a=setup:active",
            "a=mid:0",
            "a=recvonly",
            "a=rtcp-mux",
            "a=rtcp-rsize",
            "a=rtpmap:111 opus/48000/2",
            "a=fmtp:111 minptime=10;useinbandfec=1",
            
            "m=audio 9 UDP/TLS/RTP/SAVPF 111 63",
            "c=IN IP4 0.0.0.0",
            "a=rtcp:9 IN IP4 0.0.0.0",
            "a=ice-ufrag:zcgT",
            "a=ice-pwd:v559SXDwx4y9yAv7oeCvjsDR",
            "a=ice-options:trickle",
            "a=fingerprint:sha-256 F7:C8:B3:87:4A:AD:5A:86:48:1B:51:04:BE:CE:3B:D6:D3:7C:25:63:3E:9C:2B:F6:5B:8C:65:1F:72:8A:11:61",
            "a=setup:active",
            "a=mid:1",
            "a=recvonly",
            "a=rtcp-mux",
            "a=rtcp-rsize",
            "a=rtpmap:112 opus/48000/2",
            "a=fmtp:112 minptime=10;useinbandfec=1"
        ]
        .map { subject.visit(line: $0) }

        XCTAssertEqual(actual, expected)
    }
}
