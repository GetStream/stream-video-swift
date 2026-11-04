//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class CollectUserFeedbackRequest: @unchecked Sendable, Codable, JSONEncodable {
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom)
        self.rating = try container.decode(Int.self, forKey: .rating)
        self.reason = try container.decodeIfPresent(String.self, forKey: .reason)
        self.sdk = try container.decode(String.self, forKey: .sdk)
        self.sdkVersion = try container.decode(String.self, forKey: .sdkVersion)
        self.userSessionId = try container.decodeIfPresent(String.self, forKey: .userSessionId)
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
