//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
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

    func test_APIError_usesStreamCoreType() {
        XCTAssertEqual(String(reflecting: APIError.self), "StreamCore.APIError")
    }

    func test_encodeToJSON_returnsGeneratedClientShape() throws {
        let subject = APIError(
            code: 1,
            message: "message",
            statusCode: 400
        )
        let jsonEncodable: any JSONEncodable = subject

        let encoded = try XCTUnwrap(jsonEncodable.encodeToJSON() as? String)
        let data = try XCTUnwrap(Data(base64Encoded: encoded))
        let decoded = try JSONDecoder.default.decode(APIError.self, from: data)

        XCTAssertEqual(decoded, subject)
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
