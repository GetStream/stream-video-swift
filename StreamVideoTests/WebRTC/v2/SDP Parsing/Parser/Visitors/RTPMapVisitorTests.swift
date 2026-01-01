//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class RTPMapVisitor_Tests: XCTestCase, @unchecked Sendable {

    private var subject: RTPMapVisitor! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - visit(line:)

    func test_visit_withValidRTPMapLine() {
        let line = "a=rtpmap:96 opus/48000/2"
        subject.visit(line: line)
        XCTAssertEqual(subject.payloadType(for: "opus"), 96)
    }

    func test_visit_withInvalidRTPMapLine() {
        let line = "a=rtpmap:invalid opus/48000/2"
        subject.visit(line: line)
        XCTAssertNil(subject.payloadType(for: "opus"))
    }

    func test_visit_withMissingCodecName() {
        let line = "a=rtpmap:96"
        subject.visit(line: line)
        XCTAssertNil(subject.payloadType(for: ""))
    }

    func test_visit_withMultipleRTPMapLines() {
        let lines = [
            "a=rtpmap:96 opus/48000/2",
            "a=rtpmap:97 VP8/90000",
            "a=rtpmap:98 H264/90000"
        ]
        lines.forEach { subject.visit(line: $0) }
        XCTAssertEqual(subject.payloadType(for: "opus"), 96)
        XCTAssertEqual(subject.payloadType(for: "vp8"), 97)
        XCTAssertEqual(subject.payloadType(for: "h264"), 98)
    }

    // MARK: - payloadType(for:)

    func test_payloadType_forExistingCodec() {
        let line = "a=rtpmap:96 opus/48000/2"
        subject.visit(line: line)
        XCTAssertEqual(subject.payloadType(for: "opus"), 96)
    }

    func test_payloadType_forNonExistingCodec() {
        XCTAssertNil(subject.payloadType(for: "nonexistent"))
    }
}
