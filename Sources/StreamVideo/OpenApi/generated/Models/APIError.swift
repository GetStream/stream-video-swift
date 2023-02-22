//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct APIError: Codable, JSONEncodable, Hashable {

    /** Response HTTP status code */
    internal var statusCode: Double
    /** API error code */
    internal var code: Double
    /** Additional error-specific information */
    internal var details: [Double]
    /** Request duration */
    internal var duration: String
    /** Additional error info */
    internal var exceptionFields: [String: String]?
    /** Message describing an error */
    internal var message: String
    /** URL with additional information */
    internal var moreInfo: String

    internal init(
        statusCode: Double,
        code: Double,
        details: [Double],
        duration: String,
        exceptionFields: [String: String]? = nil,
        message: String,
        moreInfo: String
    ) {
        self.statusCode = statusCode
        self.code = code
        self.details = details
        self.duration = duration
        self.exceptionFields = exceptionFields
        self.message = message
        self.moreInfo = moreInfo
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case statusCode = "StatusCode"
        case code
        case details
        case duration
        case exceptionFields = "exception_fields"
        case message
        case moreInfo = "more_info"
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(statusCode, forKey: .statusCode)
        try container.encode(code, forKey: .code)
        try container.encode(details, forKey: .details)
        try container.encode(duration, forKey: .duration)
        try container.encodeIfPresent(exceptionFields, forKey: .exceptionFields)
        try container.encode(message, forKey: .message)
        try container.encode(moreInfo, forKey: .moreInfo)
    }
}
