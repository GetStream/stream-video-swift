//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// The ring state of a call session: who accepted, rejected, or missed the ring.
public final class GetCallRingStateResponse: @unchecked Sendable, Decodable {
    /// Users that accepted the call, mapped to when they accepted
    public var acceptedBy: [String: Date]
    /// The CID of the call
    public var callCid: String
    /// When the call ended
    public var callEndedAt: Date?
    /// The user that created the call, i.e. the caller
    public var createdByUserId: String
    /// Duration of the request in milliseconds
    public var duration: String
    /// Users that missed the call, mapped to when they were marked as missed
    public var missedBy: [String: Date]
    /// Users that rejected the call, mapped to when they rejected
    public var rejectedBy: [String: Date]
    /// When the call session ended
    public var sessionEndedAt: Date?
    /// The call session this state belongs to, empty when the call has never rung
    public var sessionId: String
    /// When the call session started
    public var sessionStartedAt: Date?

    public init(
        acceptedBy: [String: Date],
        callCid: String,
        callEndedAt: Date? = nil,
        createdByUserId: String,
        duration: String,
        missedBy: [String: Date],
        rejectedBy: [String: Date],
        sessionEndedAt: Date? = nil,
        sessionId: String,
        sessionStartedAt: Date? = nil
    ) {
        self.acceptedBy = acceptedBy
        self.callCid = callCid
        self.callEndedAt = callEndedAt
        self.createdByUserId = createdByUserId
        self.duration = duration
        self.missedBy = missedBy
        self.rejectedBy = rejectedBy
        self.sessionEndedAt = sessionEndedAt
        self.sessionId = sessionId
        self.sessionStartedAt = sessionStartedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.acceptedBy = try container.decode([String: Date].self, forKey: .acceptedBy)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.callEndedAt = try container.decodeIfPresent(Date.self, forKey: .callEndedAt)
        self.createdByUserId = try container.decode(String.self, forKey: .createdByUserId)
        self.duration = try container.decode(String.self, forKey: .duration)
        self.missedBy = try container.decode([String: Date].self, forKey: .missedBy)
        self.rejectedBy = try container.decode([String: Date].self, forKey: .rejectedBy)
        self.sessionEndedAt = try container.decodeIfPresent(Date.self, forKey: .sessionEndedAt)
        self.sessionId = try container.decode(String.self, forKey: .sessionId)
        self.sessionStartedAt = try container.decodeIfPresent(Date.self, forKey: .sessionStartedAt)
    }
}

extension GetCallRingStateResponse: Hashable {
    public static func == (lhs: GetCallRingStateResponse, rhs: GetCallRingStateResponse) -> Bool {
        lhs.acceptedBy == rhs.acceptedBy &&
            lhs.callCid == rhs.callCid &&
            lhs.callEndedAt == rhs.callEndedAt &&
            lhs.createdByUserId == rhs.createdByUserId &&
            lhs.duration == rhs.duration &&
            lhs.missedBy == rhs.missedBy &&
            lhs.rejectedBy == rhs.rejectedBy &&
            lhs.sessionEndedAt == rhs.sessionEndedAt &&
            lhs.sessionId == rhs.sessionId &&
            lhs.sessionStartedAt == rhs.sessionStartedAt
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(acceptedBy)
        hasher.combine(callCid)
        hasher.combine(callEndedAt)
        hasher.combine(createdByUserId)
        hasher.combine(duration)
        hasher.combine(missedBy)
        hasher.combine(rejectedBy)
        hasher.combine(sessionEndedAt)
        hasher.combine(sessionId)
        hasher.combine(sessionStartedAt)
    }
}
