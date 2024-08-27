//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct APIError: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var code: Int
    public var details: [Int]
    public var duration: String
    public var exceptionFields: [String: String]? = nil
    public var message: String
    public var moreInfo: String
    public var statusCode: Int

    public init(
        code: Int,
        details: [Int],
        duration: String,
        exceptionFields: [String: String]? = nil,
        message: String,
        moreInfo: String,
        statusCode: Int
    ) {
        self.code = code
        self.details = details
        self.duration = duration
        self.exceptionFields = exceptionFields
        self.message = message
        self.moreInfo = moreInfo
        self.statusCode = statusCode
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case code
        case details
        case duration
        case exceptionFields = "exception_fields"
        case message
        case moreInfo = "more_info"
        case statusCode = "StatusCode"
    }
}
