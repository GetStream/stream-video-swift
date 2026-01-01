//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class SDPParser_Tests: XCTestCase, @unchecked Sendable {

    private var visitor: RTPMapVisitor! = .init()
    private var subject: SDPParser! = .init()

    override func setUp() {
        super.setUp()
        subject.registerVisitor(visitor)
    }

    override func tearDown() {
        subject = nil
        visitor = nil
        super.tearDown()
    }

    // MARK: - parse(sdp:)

    func test_parse_withValidSDP() async {
        let sdp = "v=0\r\no=- 46117317 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\na=rtpmap:96 opus/48000/2\r\na=rtpmap:97 VP8/90000\r\n"
        await subject.parse(sdp: sdp)
        XCTAssertEqual(visitor.payloadType(for: "opus"), 96)
        XCTAssertEqual(visitor.payloadType(for: "vp8"), 97)
    }

    func test_parse_withInvalidSDP() async {
        let sdp = """
        v=0
        o=- 46117317 2 IN IP4 127.0.0.1
        s=-
        t=0 0
        a=invalid:96 opus/48000/2
        """
        await subject.parse(sdp: sdp)
        XCTAssertNil(visitor.payloadType(for: "opus"))
    }

    func test_parse_withMultipleVisitors() async {
        let sdp = "v=0\r\no=- 46117317 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\na=rtpmap:96 opus/48000/2\r\na=rtpmap:97 VP8/90000\r\n"
        let visitor1 = RTPMapVisitor()
        let visitor2 = RTPMapVisitor()
        subject.registerVisitor(visitor1)
        subject.registerVisitor(visitor2)
        await subject.parse(sdp: sdp)
        XCTAssertEqual(visitor1.payloadType(for: "opus"), 96)
        XCTAssertEqual(visitor1.payloadType(for: "vp8"), 97)
        XCTAssertEqual(visitor2.payloadType(for: "opus"), 96)
        XCTAssertEqual(visitor2.payloadType(for: "vp8"), 97)
    }
}
