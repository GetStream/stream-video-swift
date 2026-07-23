//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

extension Stream_Video_Sfu_Models_Error:
    Error,
    ReflectiveStringConvertible {}

/// A client error emitted by Stream.
public typealias ClientError = StreamCore.ClientError

extension Error {
    var isRateLimitError: Bool {
        if let error = (self as? ClientError)?.underlyingError as? ErrorPayload,
           error.statusCode == 429 {
            return true
        }
        return false
    }
}

extension Error {
    var isTokenExpiredError: Bool {
        if let error = self as? APIError, ClosedRange.tokenInvalidErrorCodes ~= error.code {
            return true
        }
        return false
    }
    
    var hasClientErrors: Bool {
        if let apiError = self as? APIError,
           ClosedRange.clientErrorCodes ~= apiError.statusCode {
            return false
        }
        return true
    }
}

extension ClosedRange where Bound == Int {
    /// The error codes for token-related errors. Typically, a refreshed token is required to recover.
    static let tokenInvalidErrorCodes: Self = 40...42
    
    /// The range of HTTP request status codes for client errors.
    static let clientErrorCodes: Self = 400...499
}

struct APIErrorContainer: Codable {
    let error: APIError
}
