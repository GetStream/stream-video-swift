//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class APIError: @unchecked Sendable, Codable, JSONEncodable, Hashable, ReflectiveStringConvertible {

    public var code: Int
    public var details: [Int]
    public var duration: String
    public var exceptionFields: [String: String]?
    public var message: String
    public var moreInfo: String
    public var statusCode: Int
    public var unrecoverable: Bool?

    public init(
        code: Int,
        details: [Int],
        duration: String,
        exceptionFields: [String: String]? = nil,
        message: String,
        moreInfo: String,
        statusCode: Int,
        unrecoverable: Bool? = nil
    ) {
        self.code = code
        self.details = details
        self.duration = duration
        self.exceptionFields = exceptionFields
        self.message = message
        self.moreInfo = moreInfo
        self.statusCode = statusCode
        self.unrecoverable = unrecoverable
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case code
        case details
        case duration
        case exceptionFields = "exception_fields"
        case message
        case moreInfo = "more_info"
        case statusCode = "StatusCode"
        case unrecoverable
    }
    
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        lhs.code == rhs.code &&
            lhs.details == rhs.details &&
            lhs.duration == rhs.duration &&
            lhs.exceptionFields == rhs.exceptionFields &&
            lhs.message == rhs.message &&
            lhs.moreInfo == rhs.moreInfo &&
            lhs.statusCode == rhs.statusCode &&
            lhs.unrecoverable == rhs.unrecoverable
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
        hasher.combine(details)
        hasher.combine(duration)
        hasher.combine(exceptionFields)
        hasher.combine(message)
        hasher.combine(moreInfo)
        hasher.combine(statusCode)
        hasher.combine(unrecoverable)
    }
}
