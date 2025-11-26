//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension Stream_Video_Sfu_Models_Error: Error, ReflectiveStringConvertible {}

/// A Client error.
public class ClientError: Error, CustomStringConvertible, @unchecked Sendable {
    public struct Location: Equatable, Sendable, CustomStringConvertible {
        public let file: String
        public let line: Int
        public var description: String { "{ file:\(file), line:\(line) }" }
    }
    
    /// The file and line number which emitted the error.
    public let location: Location?
    
    private let message: String?

    /// An underlying error.
    public let underlyingError: Error?
    
    public let apiError: APIError?
    
    var errorDescription: String? {
        if let apiError {
            return apiError.message
        } else {
            return underlyingError.map(String.init(describing:))
        }
    }
    
    /// Retrieve the localized description for this error.
    public var localizedDescription: String { message ?? errorDescription ?? "" }

    public var description: String {
        var result = "ClientError {"
        result += " location:\(location)"
        if let message {
            result += " message:\(message)"
        }
        if let apiError {
            result += ", apiError:\(apiError)"
        }
        if let underlyingError {
            result += ", underlyingError:\(underlyingError)"
        }
        if let errorDescription {
            result += ", errorDescription:\(errorDescription)"
        }
        result += " }"
        return result
    }

    /// A client error based on an external general error.
    /// - Parameters:
    ///   - error: an external error.
    ///   - file: a file name source of an error.
    ///   - line: a line source of an error.
    public init(with error: Error? = nil, _ file: StaticString = #fileID, _ line: UInt = #line) {
        underlyingError = error
        message = error?.localizedDescription ?? nil
        location = .init(file: "\(file)", line: Int(line))
        if let aErr = error as? APIError {
            apiError = aErr
        } else {
            apiError = nil
        }
    }
    
    /// An error based on a message.
    /// - Parameters:
    ///   - message: an error message.
    ///   - file: a file name source of an error.
    ///   - line: a line source of an error.
    public init(_ message: String, _ file: StaticString = #fileID, _ line: UInt = #line) {
        self.message = message
        location = .init(file: "\(file)", line: Int(line))
        underlyingError = nil
        apiError = nil
    }
}

extension ClientError {
    /// An unexpected error.
    public final class Unexpected: ClientError, @unchecked Sendable {}

    /// An unknown error.
    public final class Unknown: ClientError, @unchecked Sendable {}

    /// Networking error.
    public final class NetworkError: ClientError, @unchecked Sendable {}

    /// Represents a network-related error indicating that the network is unavailable.
    public final class NetworkNotAvailable: ClientError, @unchecked Sendable {}

    /// Permissions error.
    public final class MissingPermissions: ClientError, @unchecked Sendable {}

    /// Invalid url error.
    public final class InvalidURL: ClientError, @unchecked Sendable {}
}

// This should probably live only in the test target since it's not "true" equatable
extension ClientError: Equatable {
    public static func == (lhs: ClientError, rhs: ClientError) -> Bool {
        type(of: lhs) == type(of: rhs)
            && String(describing: lhs.underlyingError) == String(describing: rhs.underlyingError)
            && String(describing: lhs.localizedDescription) == String(describing: rhs.localizedDescription)
    }
}

extension ClientError {
    /// Returns `true` if underlaying error is `ErrorPayload` with code is inside invalid token codes range.
    var isInvalidTokenError: Bool {
        (underlyingError as? ErrorPayload)?.isInvalidTokenError == true
            || apiError?.isTokenExpiredError == true
    }
}

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

extension APIError: Error {}
