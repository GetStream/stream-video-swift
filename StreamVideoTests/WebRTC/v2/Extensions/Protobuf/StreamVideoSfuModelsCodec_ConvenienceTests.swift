//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class StreamVideoSfuModelsCodec_ConvenienceTests: XCTestCase, @unchecked Sendable {

    func test_initWithRTCRtpCodecCapability_withAllValues() {
        let codecCapability = MockRTCRtpCodecCapability()
        codecCapability.stub(for: \.name, with: "opus")
        codecCapability.stub(for: \.fmtp, with: "minptime=10")
        codecCapability.stub(for: \.clockRate, with: NSNumber(value: 48000))
        codecCapability.stub(for: \.preferredPayloadType, with: NSNumber(value: 111))

        let codec = Stream_Video_Sfu_Models_Codec(codecCapability)

        XCTAssertEqual(codec.name, "opus")
        XCTAssertEqual(codec.fmtp, "minptime=10")
        XCTAssertEqual(codec.clockRate, 48000)
        XCTAssertEqual(codec.payloadType, 111)
    }

    func test_initWithRTCRtpCodecCapability_withMissingValues() {
        let codecCapability = MockRTCRtpCodecCapability()
        codecCapability.stub(for: \.name, with: "VP8")
        codecCapability.stub(for: \.fmtp, with: "")
        codecCapability.stub(for: \.clockRate, with: nil)
        codecCapability.stub(for: \.preferredPayloadType, with: nil)

        let codec = Stream_Video_Sfu_Models_Codec(codecCapability)

        XCTAssertEqual(codec.name, "VP8")
        XCTAssertEqual(codec.fmtp, "")
        XCTAssertEqual(codec.clockRate, 0)
        XCTAssertEqual(codec.payloadType, 0)
    }

    func test_initWithRTCRtpCodecCapability_withPartialValues() {
        let codecCapability = MockRTCRtpCodecCapability()
        codecCapability.stub(for: \.name, with: "H264")
        codecCapability.stub(for: \.fmtp, with: "profile-level-id=42e01f")
        codecCapability.stub(for: \.clockRate, with: NSNumber(value: 90000))
        codecCapability.stub(for: \.preferredPayloadType, with: nil)

        let codec = Stream_Video_Sfu_Models_Codec(codecCapability)

        XCTAssertEqual(codec.name, "H264")
        XCTAssertEqual(codec.fmtp, "profile-level-id=42e01f")
        XCTAssertEqual(codec.clockRate, 90000)
        XCTAssertEqual(codec.payloadType, 0)
    }
}
