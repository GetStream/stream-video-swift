//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallUserFeedbackSubmittedEvent: @unchecked Sendable,  Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    public var custom: [String: RawJSON]?
    public var rating: Int
    public var reason: String?
    public var sdk: String?
    public var sdkVersion: String?
    public var sessionId: String
    public var type: String = "call.user_feedback_submitted"
    public var user: UserResponse

    public init(callCid: String, createdAt: Date, custom: [String: RawJSON]? = nil, rating: Int, reason: String? = nil, sdk: String? = nil, sdkVersion: String? = nil, sessionId: String, user: UserResponse) {
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

public enum CodingKeys: String, CodingKey, CaseIterable {
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
