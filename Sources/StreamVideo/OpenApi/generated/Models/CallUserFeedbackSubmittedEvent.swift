//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a user submits feedback for a call.
public final class CallUserFeedbackSubmittedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    /// Custom data provided by the user
    public var custom: [String: RawJSON]?
    /// The rating given by the user (1-5)
    public var rating: Int
    /// The reason provided by the user for the rating
    public var reason: String?
    public var sdk: String?
    public var sdkVersion: String?
    /// Call session ID
    public var sessionId: String
    /// The type of event, "call.user_feedback" in this case
    public var type: String = "call.user_feedback_submitted"
    /// User response object
    public var user: UserResponse

    public init(
        callCid: String,
        createdAt: Date,
        custom: [String: RawJSON]? = nil,
        rating: Int,
        reason: String? = nil,
        sdk: String? = nil,
        sdkVersion: String? = nil,
        sessionId: String,
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
        self.user = user
    }

    public enum CodingKeys: String, CodingKey {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case custom
        case rating
        case reason
        case sdk
        case sdkVersion = "sdk_version"
        case sessionId = "session_id"
        case type
        case user
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
