//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class StereoEnableVisitor_Tests: XCTestCase, @unchecked Sendable {

    private var subject: StereoEnableVisitor! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - visit(line:)

    func test_visit_oneMidOneEnabled_withValidMediaLines() throws {
        let lines = [
            "m=audio 51808 UDP/TLS/RTP/SAVPF 111 63 (19 more lines) direction=sendrecv mid=0",
            "c=IN IP4 18.119.157.125",
            "a=rtcp:51808 IN IP4 18.119.157.125",
            "a=candidate:965407073 1 udp 2130706431 18.119.157.125 51808 typ host generation 0",
            "a=candidate:965407073 2 udp 2130706431 18.119.157.125 51808 typ host generation 0",
            "a=ice-ufrag:AFJnYPvMfEaZeHdt",
            "a=ice-pwd:mbwUwrcoSApXwOyGrQOAsipWsfFGHcww",
            "a=fingerprint:sha-256 13:79:52:41:12:BB:A7:5D:39:F0:9B:1A:95:58:94:D6:F9:D3:1E:00:A4:9D:CA:12:26:AE:7C:2A:E1:FC:42:F4",
            "a=setup:actpass",
            "a=mid:0",
            "a=sendrecv",
            "a=msid:a1e5f21f716affb7:TRACK_TYPE_AUDIO:eO 5040549b-8458-4646-892d-ad08f4475568",
            "a=rtcp-mux",
            "a=rtcp-rsize",
            "a=rtpmap:111 opus/48000/2",
            "a=fmtp:111 maxaveragebitrate=510000;minptime=10;sprop-stereo=1;stereo=1;useinbandfec=1"
        ]

        lines.forEach { subject.visit(line: $0) }

        XCTAssertEqual(subject.found.count, 1)
        let entry = try XCTUnwrap(subject.found.first)
        XCTAssertEqual(entry.key, "0")
        XCTAssertEqual(entry.value.mid, "0")
        XCTAssertEqual(entry.value.codecPayload, "111")
        XCTAssertTrue(entry.value.isStereoEnabled)
    }

    func test_visit_moreThanOneMidMoreThanOneEnabled_withValidMediaLines() throws {
        let lines = [
            "m=audio 51808 UDP/TLS/RTP/SAVPF 111 63 (19 more lines) direction=sendrecv mid=0",
            "c=IN IP4 18.119.157.125",
            "a=rtcp:51808 IN IP4 18.119.157.125",
            "a=candidate:965407073 1 udp 2130706431 18.119.157.125 51808 typ host generation 0",
            "a=candidate:965407073 2 udp 2130706431 18.119.157.125 51808 typ host generation 0",
            "a=ice-ufrag:AFJnYPvMfEaZeHdt",
            "a=ice-pwd:mbwUwrcoSApXwOyGrQOAsipWsfFGHcww",
            "a=fingerprint:sha-256 13:79:52:41:12:BB:A7:5D:39:F0:9B:1A:95:58:94:D6:F9:D3:1E:00:A4:9D:CA:12:26:AE:7C:2A:E1:FC:42:F4",
            "a=setup:actpass",
            "a=mid:0",
            "a=sendrecv",
            "a=msid:a1e5f21f716affb7:TRACK_TYPE_AUDIO:eO 5040549b-8458-4646-892d-ad08f4475568",
            "a=rtcp-mux",
            "a=rtcp-rsize",
            "a=rtpmap:111 opus/48000/2",
            "a=fmtp:111 maxaveragebitrate=510000;minptime=10;sprop-stereo=1;stereo=1;useinbandfec=1",
            
            "m=audio 51808 UDP/TLS/RTP/SAVPF 111 63 (19 more lines) direction=sendrecv mid=0",
            "c=IN IP4 18.119.157.125",
            "a=rtcp:51808 IN IP4 18.119.157.125",
            "a=candidate:965407073 1 udp 2130706431 18.119.157.125 51808 typ host generation 0",
            "a=candidate:965407073 2 udp 2130706431 18.119.157.125 51808 typ host generation 0",
            "a=ice-ufrag:AFJnYPvMfEaZeHdt",
            "a=ice-pwd:mbwUwrcoSApXwOyGrQOAsipWsfFGHcww",
            "a=fingerprint:sha-256 13:79:52:41:12:BB:A7:5D:39:F0:9B:1A:95:58:94:D6:F9:D3:1E:00:A4:9D:CA:12:26:AE:7C:2A:E1:FC:42:F4",
            "a=setup:actpass",
            "a=mid:1",
            "a=sendrecv",
            "a=msid:a1e5f21f716affb7:TRACK_TYPE_AUDIO:eO 5040549b-8458-4646-892d-ad08f4475568",
            "a=rtcp-mux",
            "a=rtcp-rsize",
            "a=rtpmap:112 opus/48000/2",
            "a=fmtp:112 maxaveragebitrate=510000;minptime=10;sprop-stereo=1;stereo=1;useinbandfec=1"
        ]

        lines.forEach { subject.visit(line: $0) }

        XCTAssertEqual(subject.found.count, 2)
        let entryA = try XCTUnwrap(subject.found["0"])
        XCTAssertEqual(entryA.mid, "0")
        XCTAssertEqual(entryA.codecPayload, "111")
        XCTAssertTrue(entryA.isStereoEnabled)

        let entryB = try XCTUnwrap(subject.found["1"])
        XCTAssertEqual(entryB.mid, "1")
        XCTAssertEqual(entryB.codecPayload, "112")
        XCTAssertTrue(entryB.isStereoEnabled)
    }

    func test_visit_moreThanOneMidOneEnabled_withValidMediaLines() throws {
        let lines = [
            "m=audio 51808 UDP/TLS/RTP/SAVPF 111 63 (19 more lines) direction=sendrecv mid=0",
            "c=IN IP4 18.119.157.125",
            "a=rtcp:51808 IN IP4 18.119.157.125",
            "a=candidate:965407073 1 udp 2130706431 18.119.157.125 51808 typ host generation 0",
            "a=candidate:965407073 2 udp 2130706431 18.119.157.125 51808 typ host generation 0",
            "a=ice-ufrag:AFJnYPvMfEaZeHdt",
            "a=ice-pwd:mbwUwrcoSApXwOyGrQOAsipWsfFGHcww",
            "a=fingerprint:sha-256 13:79:52:41:12:BB:A7:5D:39:F0:9B:1A:95:58:94:D6:F9:D3:1E:00:A4:9D:CA:12:26:AE:7C:2A:E1:FC:42:F4",
            "a=setup:actpass",
            "a=mid:0",
            "a=sendrecv",
            "a=msid:a1e5f21f716affb7:TRACK_TYPE_AUDIO:eO 5040549b-8458-4646-892d-ad08f4475568",
            "a=rtcp-mux",
            "a=rtcp-rsize",
            "a=rtpmap:111 opus/48000/2",
            "a=fmtp:111 maxaveragebitrate=510000;minptime=10;;useinbandfec=1",
            
            "m=audio 51808 UDP/TLS/RTP/SAVPF 111 63 (19 more lines) direction=sendrecv mid=0",
            "c=IN IP4 18.119.157.125",
            "a=rtcp:51808 IN IP4 18.119.157.125",
            "a=candidate:965407073 1 udp 2130706431 18.119.157.125 51808 typ host generation 0",
            "a=candidate:965407073 2 udp 2130706431 18.119.157.125 51808 typ host generation 0",
            "a=ice-ufrag:AFJnYPvMfEaZeHdt",
            "a=ice-pwd:mbwUwrcoSApXwOyGrQOAsipWsfFGHcww",
            "a=fingerprint:sha-256 13:79:52:41:12:BB:A7:5D:39:F0:9B:1A:95:58:94:D6:F9:D3:1E:00:A4:9D:CA:12:26:AE:7C:2A:E1:FC:42:F4",
            "a=setup:actpass",
            "a=mid:1",
            "a=sendrecv",
            "a=msid:a1e5f21f716affb7:TRACK_TYPE_AUDIO:eO 5040549b-8458-4646-892d-ad08f4475568",
            "a=rtcp-mux",
            "a=rtcp-rsize",
            "a=rtpmap:112 opus/48000/2",
            "a=fmtp:112 maxaveragebitrate=510000;minptime=10;sprop-stereo=1;stereo=1;useinbandfec=1"
        ]

        lines.forEach { subject.visit(line: $0) }

        XCTAssertEqual(subject.found.count, 1)
        let entry = try XCTUnwrap(subject.found.first?.value)
        XCTAssertEqual(entry.mid, "1")
        XCTAssertEqual(entry.codecPayload, "112")
        XCTAssertTrue(entry.isStereoEnabled)
    }
}
