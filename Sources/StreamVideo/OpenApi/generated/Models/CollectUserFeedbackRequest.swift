//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class CollectUserFeedbackRequest: @unchecked Sendable, Encodable, JSONEncodable {
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

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encode(rating, forKey: .rating)
        try container.encodeIfPresent(reason, forKey: .reason)
        try container.encode(sdk, forKey: .sdk)
        try container.encode(sdkVersion, forKey: .sdkVersion)
        try container.encodeIfPresent(userSessionId, forKey: .userSessionId)
    }
}

extension CollectUserFeedbackRequest: Hashable {
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
