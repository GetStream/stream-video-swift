//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CollectUserFeedbackRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var custom: [String: RawJSON]?
    public var rating: Int
    public var reason: String?
    public var sdk: String
    public var sdkVersion: String
    public var userSessionId: String?

    public init(
        custom: [String: RawJSON]? = nil,
        rating: Int,
        reason: String? = nil,
        sdk: String,
        sdkVersion: String,
        userSessionId: String? = nil
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
    
    public static func == (lhs: CollectUserFeedbackRequest, rhs: CollectUserFeedbackRequest) -> Bool {
        lhs.custom == rhs.custom &&
            lhs.rating == rhs.rating &&
            lhs.reason == rhs.reason &&
            lhs.sdk == rhs.sdk &&
            lhs.sdkVersion == rhs.sdkVersion &&
            lhs.userSessionId == rhs.userSessionId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(custom)
        hasher.combine(rating)
        hasher.combine(reason)
        hasher.combine(sdk)
        hasher.combine(sdkVersion)
        hasher.combine(userSessionId)
    }
}
