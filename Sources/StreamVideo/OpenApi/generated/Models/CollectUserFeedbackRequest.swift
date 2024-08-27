//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CollectUserFeedbackRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var custom: [String: RawJSON]? = nil
    public var rating: Int
    public var reason: String? = nil
    public var sdk: String
    public var sdkVersion: String
    public var userSessionId: String

    public init(
        custom: [String: RawJSON]? = nil,
        rating: Int,
        reason: String? = nil,
        sdk: String,
        sdkVersion: String,
        userSessionId: String
    ) {
        self.custom = custom
        self.rating = rating
        self.reason = reason
        self.sdk = sdk
        self.sdkVersion = sdkVersion
        self.userSessionId = userSessionId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case rating
        case reason
        case sdk
        case sdkVersion = "sdk_version"
        case userSessionId = "user_session_id"
    }
}
