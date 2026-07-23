//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class ClientEventFailure_Tests: XCTestCase, @unchecked Sendable {

    func test_init_withFailureCode_usesDefaultReason() {
        let failure = ClientEventFailure(code: .requestTimeout)

        XCTAssertEqual(failure.code, "REQUEST_TIMEOUT")
        XCTAssertEqual(failure.reason, ClientEventFailureCode.requestTimeout.defaultReason)
    }

    func test_init_withCustomReason_usesProvidedReason() {
        let failure = ClientEventFailure(code: .clientAborted, reason: "left during retry")

        XCTAssertEqual(failure.code, "CLIENT_ABORTED")
        XCTAssertEqual(failure.reason, "left during retry")
    }

    func test_init_fromCancellationError_mapsToClientAborted() {
        let failure = ClientEventFailure(CancellationError())

        XCTAssertEqual(failure.code, "CLIENT_ABORTED")
    }

    func test_init_fromTimeOutError_mapsToRequestTimeout() {
        let failure = ClientEventFailure(TimeOutError())

        XCTAssertEqual(failure.code, "REQUEST_TIMEOUT")
    }

    func test_init_fromURLErrorTimedOut_mapsToRequestTimeout() {
        let failure = ClientEventFailure(URLError(.timedOut))

        XCTAssertEqual(failure.code, "REQUEST_TIMEOUT")
    }

    func test_init_fromURLErrorOffline_mapsToNetworkOffline() {
        let failure = ClientEventFailure(URLError(.notConnectedToInternet))

        XCTAssertEqual(failure.code, "NETWORK_OFFLINE")
    }

    func test_init_fromAPIError_usesBackendCodeAndMessage() {
        let apiError = APIError(
            code: 17,
            details: [],
            duration: "",
            message: "validation failed",
            moreInfo: "",
            statusCode: 400
        )

        let failure = ClientEventFailure(apiError)

        XCTAssertEqual(failure.code, "17")
        XCTAssertEqual(failure.reason, "validation failed")
    }
}
