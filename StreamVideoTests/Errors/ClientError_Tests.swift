//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore
@testable import StreamVideo
import XCTest

final class ClientError_Tests: XCTestCase, @unchecked Sendable {
    func test_init_videoAPIError_preservesPublicAPIError() throws {
        let apiError = makeAPIError(code: 1)

        let subject = ClientError(with: apiError)
        let exposedAPIError = try XCTUnwrap(subject.apiError)

        XCTAssertTrue(exposedAPIError === apiError)
    }

    func test_encodeToJSON_preservesLegacyWireShape() throws {
        let subject = makeAPIError(code: 1)
        let jsonEncodable: any StreamCore.JSONEncodable = subject

        let encoded = try XCTUnwrap(jsonEncodable.encodeToJSON() as? String)
        let data = try XCTUnwrap(Data(base64Encoded: encoded))

        AssertJSONEqual(
            data,
            """
            {
              "code": 1,
              "details": [2],
              "duration": "3ms",
              "exception_fields": {"field": "reason"},
              "message": "message",
              "more_info": "more info",
              "StatusCode": 400,
              "unrecoverable": false
            }
            """.data(using: .utf8)!
        )
    }

    func test_APIError_equality_preservesLegacyFields() {
        let subject = makeAPIError(code: 1)
        let equalValue = makeAPIError(code: 1)
        let differentValue = makeAPIError(code: 2)

        XCTAssertEqual(subject, equalValue)
        XCTAssertNotEqual(subject, differentValue)
    }

    func test_errorPayload_isInvalidTokenError_preservesLegacyBoundaries() {
        let cases = [
            (code: 39, expected: false),
            (code: 40, expected: true),
            (code: 42, expected: true),
            (code: 43, expected: false)
        ]

        for testCase in cases {
            let errorPayload = ErrorPayload(
                code: testCase.code,
                message: "message",
                statusCode: 401
            )

            XCTAssertEqual(
                errorPayload.isInvalidTokenError,
                testCase.expected,
                "ErrorPayload code \(testCase.code)"
            )
        }
    }

    func test_clientError_isInvalidTokenError_usesStreamCoreBoundaries() {
        let cases = [
            (code: 1, expected: false),
            (code: 2, expected: true),
            (code: 40, expected: false),
            (code: 41, expected: true),
            (code: 43, expected: true),
            (code: 44, expected: false)
        ]

        for testCase in cases {
            XCTAssertEqual(
                ClientError(with: makeAPIError(code: testCase.code))
                    .isInvalidTokenError,
                testCase.expected,
                "APIError code \(testCase.code)"
            )
        }
    }

    func test_clientError_isTokenExpiredError_usesStreamCoreBoundary() {
        let cases = [
            (code: 39, expected: false),
            (code: 40, expected: true),
            (code: 41, expected: false)
        ]

        for testCase in cases {
            XCTAssertEqual(
                ClientError(with: makeAPIError(code: testCase.code))
                    .isTokenExpiredError,
                testCase.expected,
                "APIError code \(testCase.code)"
            )
        }
    }

    func test_rateLimitError_isEphemeralError() {
        let errorPayload = ErrorPayload(
            code: 9,
            message: .unique,
            statusCode: 429
        )

        let error = ClientError(with: errorPayload)

        // Assert `isRateLimitError` returns true
        XCTAssertTrue(error.isRateLimitError)
    }

    private func makeAPIError(code: Int) -> APIError {
        APIError(
            code: code,
            details: [2],
            duration: "3ms",
            exceptionFields: ["field": "reason"],
            message: "message",
            moreInfo: "more info",
            statusCode: 400,
            unrecoverable: false
        )
    }
}
