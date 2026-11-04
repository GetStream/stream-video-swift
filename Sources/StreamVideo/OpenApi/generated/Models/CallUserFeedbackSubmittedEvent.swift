//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a user submits feedback for a call.
public final class CallUserFeedbackSubmittedEvent: Sendable, Event, Decodable, WSCallEvent {
    public let callCid: String
    public let createdAt: Date
    /// Custom data provided by the user
    public let custom: [String: RawJSON]?
    /// The rating given by the user (1-5)
    public let rating: Int
    /// The reason provided by the user for the rating
    public let reason: String?
    public let sdk: String?
    public let sdkVersion: String?
    /// Call session ID
    public let sessionId: String
    /// The type of event, "call.user_feedback" in this case
    public let type: String
    /// User response object
    public let user: UserResponse

    public init(
        callCid: String,
        createdAt: Date,
        custom: [String: RawJSON]? = nil,
        rating: Int,
        reason: String? = nil,
        sdk: String? = nil,
        sdkVersion: String? = nil,
        sessionId: String,
        type: String = "call.user_feedback_submitted",
        user: UserResponse
    ) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.custom = custom
        self.rating = rating
        self.reason = reason
        self.sdk = sdk
        self.sdkVersion = sdkVersion
        self.sessionId = sessionId
        self.type = type
        self.user = user
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom)
        self.rating = try container.decode(Int.self, forKey: .rating)
        self.reason = try container.decodeIfPresent(String.self, forKey: .reason)
        self.sdk = try container.decodeIfPresent(String.self, forKey: .sdk)
        self.sdkVersion = try container.decodeIfPresent(String.self, forKey: .sdkVersion)
        self.sessionId = try container.decode(String.self, forKey: .sessionId)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decode(UserResponse.self, forKey: .user)
    }
}

extension CallUserFeedbackSubmittedEvent: Hashable {
    public static func == (lhs: CallUserFeedbackSubmittedEvent, rhs: CallUserFeedbackSubmittedEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.rating == rhs.rating &&
            lhs.reason == rhs.reason &&
            lhs.sdk == rhs.sdk &&
            lhs.sdkVersion == rhs.sdkVersion &&
            lhs.sessionId == rhs.sessionId &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(rating)
        hasher.combine(reason)
        hasher.combine(sdk)
        hasher.combine(sdkVersion)
        hasher.combine(sessionId)
        hasher.combine(type)
        hasher.combine(user)
    }
}
