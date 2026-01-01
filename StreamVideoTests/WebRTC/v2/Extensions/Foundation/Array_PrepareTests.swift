//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class Array_PrepareTests: XCTestCase, @unchecked Sendable {

    // MARK: - RTCRtpEncodingParameters

    func test_prepare_whenElementIsRTCRtpEncodingParameters_withSVCCodecs_returnsModifiedArray() {
        let parameters = [
            RTCRtpEncodingParameters(),
            RTCRtpEncodingParameters(),
            RTCRtpEncodingParameters()
        ]

        let preparedParameters = parameters.prepare()

        XCTAssertEqual(preparedParameters[0].rid, VideoLayer.Quality.quarter.rawValue)
        XCTAssertEqual(preparedParameters[1].rid, VideoLayer.Quality.half.rawValue)
        XCTAssertEqual(preparedParameters[2].rid, VideoLayer.Quality.full.rawValue)
    }

    func test_prepare_whenElementIsRTCRtpEncodingParameters_withLessThanThreeEncodings_returnsModifiedArray() {
        let parameters = [
            RTCRtpEncodingParameters(),
            RTCRtpEncodingParameters()
        ]

        let preparedParameters = parameters.prepare()

        XCTAssertEqual(preparedParameters[0].rid, VideoLayer.Quality.quarter.rawValue)
        XCTAssertEqual(preparedParameters[1].rid, VideoLayer.Quality.half.rawValue)
    }

    func test_prepare_whenElementIsRTCRtpEncodingParameters_withMoreThanThreeEncodings_returnsModifiedArray() {
        let parameters = [
            RTCRtpEncodingParameters(),
            RTCRtpEncodingParameters(),
            RTCRtpEncodingParameters(),
            RTCRtpEncodingParameters()
        ]

        let preparedParameters = parameters.prepare()

        XCTAssertEqual(preparedParameters[0].rid, VideoLayer.Quality.quarter.rawValue)
        XCTAssertEqual(preparedParameters[1].rid, VideoLayer.Quality.half.rawValue)
        XCTAssertEqual(preparedParameters[2].rid, VideoLayer.Quality.full.rawValue)
        XCTAssertNil(preparedParameters[3].rid)
    }

    func test_prepare_whenElementIsRTCRtpEncodingParameters_withEmptyArray_returnsEmptyArray() {
        let parameters: [RTCRtpEncodingParameters] = []

        let preparedParameters = parameters.prepare()

        XCTAssertTrue(preparedParameters.isEmpty)
    }

    // MARK: - Stream_Video_Sfu_Models_VideoLayer

    func test_prepare_whenElementIsVideoLayer_withSVCCodecs_returnsModifiedArray() {
        let parameters = [
            Stream_Video_Sfu_Models_VideoLayer(),
            Stream_Video_Sfu_Models_VideoLayer(),
            Stream_Video_Sfu_Models_VideoLayer()
        ]

        let preparedParameters = parameters.prepare()

        XCTAssertEqual(preparedParameters[0].rid, VideoLayer.Quality.quarter.rawValue)
        XCTAssertEqual(preparedParameters[1].rid, VideoLayer.Quality.half.rawValue)
        XCTAssertEqual(preparedParameters[2].rid, VideoLayer.Quality.full.rawValue)
    }

    func test_prepare_whenElementIsVideoLayer_withLessThanThreeEncodings_returnsModifiedArray() {
        let parameters = [
            Stream_Video_Sfu_Models_VideoLayer(),
            Stream_Video_Sfu_Models_VideoLayer()
        ]

        let preparedParameters = parameters.prepare()

        XCTAssertEqual(preparedParameters[0].rid, VideoLayer.Quality.quarter.rawValue)
        XCTAssertEqual(preparedParameters[1].rid, VideoLayer.Quality.half.rawValue)
    }

    func test_prepare_whenElementIsVideoLayer_withMoreThanThreeEncodings_returnsModifiedArray() {
        let parameters = [
            Stream_Video_Sfu_Models_VideoLayer(),
            Stream_Video_Sfu_Models_VideoLayer(),
            Stream_Video_Sfu_Models_VideoLayer(),
            Stream_Video_Sfu_Models_VideoLayer()
        ]

        let preparedParameters = parameters.prepare()

        XCTAssertEqual(preparedParameters[0].rid, VideoLayer.Quality.quarter.rawValue)
        XCTAssertEqual(preparedParameters[1].rid, VideoLayer.Quality.half.rawValue)
        XCTAssertEqual(preparedParameters[2].rid, VideoLayer.Quality.full.rawValue)
        XCTAssertEqual(preparedParameters[3].rid, "")
    }

    func test_prepare_whenElementIsVideoLayer_withEmptyArray_returnsEmptyArray() {
        let parameters: [Stream_Video_Sfu_Models_VideoLayer] = []

        let preparedParameters = parameters.prepare()

        XCTAssertTrue(preparedParameters.isEmpty)
    }
}
