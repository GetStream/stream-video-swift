//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class StereoEnableVisitor_Tests: XCTestCase, @unchecked Sendable {

    private func makeVisitor(for payload: String = "111") -> StereoEnableVisitor {
        let visitor = StereoEnableVisitor()
        visitor.visit(line: "m=audio 9 UDP/TLS/RTP/SAVPF \(payload)")
        visitor.visit(line: "a=mid:0")
        visitor.visit(line: "a=rtpmap:\(payload) opus/48000/2")
        return visitor
    }

    func test_visit_addsStereoParametersWhenMissing() {
        let fmtpLine = "a=fmtp:111 minptime=10;useinbandfec=1"
        let originalSDP = [
            "v=0",
            "o=- 0 0 IN IP4 127.0.0.1",
            "s=-",
            "t=0 0",
            fmtpLine
        ].joined(separator: "\r\n")

        let visitor = makeVisitor()
        visitor.visit(line: fmtpLine)

        let updatedSDP = visitor.applyStereoUpdates(to: originalSDP)
        let updatedLine = "a=fmtp:111 minptime=10;useinbandfec=1;stereo=1;sprop-stereo=1;maxaveragebitrate=128000;maxplaybackrate=48000"

        XCTAssertEqual(visitor.fmtpLineReplacements[fmtpLine], updatedLine)
        XCTAssertTrue(updatedSDP.contains(updatedLine))
        XCTAssertEqual(visitor.found["0"]?.isStereoEnabled, true)
    }

    func test_visit_appendsMissingStereoCompanionParameters() {
        let fmtpLine = "a=fmtp:111 minptime=10;useinbandfec=1;stereo=1"
        let visitor = makeVisitor()
        visitor.visit(line: fmtpLine)

        let updatedLine = visitor.fmtpLineReplacements[fmtpLine]

        XCTAssertNotNil(updatedLine)
        XCTAssertTrue(updatedLine?.contains("sprop-stereo=1") == true)
        XCTAssertTrue(updatedLine?.contains("maxaveragebitrate=128000") == true)
        XCTAssertTrue(updatedLine?.contains("maxplaybackrate=48000") == true)
    }

    func test_visit_doesNotCreateReplacementWhenAlreadyStereoOptimised() {
        let fmtpLine = "a=fmtp:111 minptime=10;useinbandfec=1;stereo=1;sprop-stereo=1;maxaveragebitrate=128000;maxplaybackrate=48000"
        let visitor = makeVisitor()
        visitor.visit(line: fmtpLine)

        XCTAssertTrue(visitor.fmtpLineReplacements.isEmpty)
        XCTAssertEqual(visitor.found["0"]?.isStereoEnabled, true)
    }
}
