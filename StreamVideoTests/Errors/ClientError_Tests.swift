//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class ClientError_Tests: XCTestCase, @unchecked Sendable {
    func test_init_videoAPIError_preservesPublicAPIError() throws {
        let apiError = APIError(
            code: 1,
            details: [2],
            duration: "3ms",
            message: "message",
            moreInfo: "more info",
            statusCode: 400,
            unrecoverable: false
        )

        let subject = ClientError(with: apiError)
        let exposedAPIError: APIError = try XCTUnwrap(subject.apiError)

        XCTAssertTrue(exposedAPIError === apiError)
    }

    func test_init_streamAPIError_convertsToPublicAPIErrorPreservingFields() throws {
        let apiError = StreamAPIError(
            code: ClosedRange.tokenInvalidErrorCodes.lowerBound,
            details: [2, 3],
            duration: "4ms",
            exceptionFields: ["field": "reason"],
            message: "message",
            moreInfo: "more info",
            statusCode: 429,
            unrecoverable: true
        )

        let subject = ClientError(with: apiError)
        let exposedAPIError: APIError = try XCTUnwrap(subject.apiError)

        XCTAssertEqual(exposedAPIError.code, apiError.code)
        XCTAssertEqual(exposedAPIError.details, apiError.details)
        XCTAssertEqual(exposedAPIError.duration, apiError.duration)
        XCTAssertEqual(exposedAPIError.exceptionFields, apiError.exceptionFields)
        XCTAssertEqual(exposedAPIError.message, apiError.message)
        XCTAssertEqual(exposedAPIError.moreInfo, apiError.moreInfo)
        XCTAssertEqual(exposedAPIError.statusCode, apiError.statusCode)
        XCTAssertEqual(exposedAPIError.unrecoverable, apiError.unrecoverable)
        XCTAssertTrue(subject.isInvalidTokenError)
    }

    func test_isInvalidTokenError_whenUnderlayingErrorIsInvalidToken_returnsTrue() {
        // Create error code withing `ErrorPayload.tokenInvalidErrorCodes` range
        let error = ErrorPayload(
            code: .random(in: ClosedRange.tokenInvalidErrorCodes),
            message: .unique,
            statusCode: .unique
        )

        // Assert `isInvalidTokenError` returns true
        XCTAssertTrue(error.isInvalidTokenError)

        // Create client error wrapping the error
        let clientError = ClientError(with: error)

        // Assert `isInvalidTokenError` returns true
        XCTAssertTrue(clientError.isInvalidTokenError)
    }

    func test_isInvalidTokenError_whenUnderlayingErrorIsNotInvalidToken_returnsFalse() {
        // Create error code outside `ErrorPayload.tokenInvalidErrorCodes` range
        let error = ErrorPayload(
            code: ClosedRange.tokenInvalidErrorCodes.lowerBound - 1,
            message: .unique,
            statusCode: .unique
        )

        // Assert `isInvalidTokenError` returns false
        XCTAssertFalse(error.isInvalidTokenError)

        // Create client error wrapping the error
        let clientError = ClientError(with: error)

        // Assert `isInvalidTokenError` returns false
        XCTAssertFalse(clientError.isInvalidTokenError)
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
}
