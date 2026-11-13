//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Represents a call
public final class CallResponse: Sendable, Decodable {
    public let backstage: Bool
    public let blockedUserIds: [String]
    public let captioning: Bool
    /// The unique identifier for a call (<type>:<id>)
    public let cid: String
    /// Date/time of creation
    public let createdAt: Date
    /// User response object
    public let createdBy: UserResponse
    public let currentSessionId: String
    /// Custom data for this object
    public let custom: [String: RawJSON]
    public let egress: EgressResponse
    /// Date/time when the call ended
    public let endedAt: Date?
    /// Call ID
    public let id: String
    /// CallIngressResponse is the payload for ingress settings
    public let ingress: CallIngressResponse
    public let joinAheadTimeSeconds: Int?
    public let recording: Bool
    /// 10-digit routing number for SIP routing
    public let routingNumber: String?
    public let session: CallSessionResponse?
    public let settings: CallSettingsResponse
    /// Date/time when the call will start
    public let startsAt: Date?
    public let team: String?
    public let thumbnails: ThumbnailResponse?
    public let transcribing: Bool
    public let translating: Bool
    /// The type of call
    public let type: String
    /// Date/time of the last update
    public let updatedAt: Date

    public init(
        backstage: Bool,
        blockedUserIds: [String],
        captioning: Bool,
        cid: String,
        createdAt: Date,
        createdBy: UserResponse,
        currentSessionId: String,
        custom: [String: RawJSON],
        egress: EgressResponse,
        endedAt: Date? = nil,
        id: String,
        ingress: CallIngressResponse,
        joinAheadTimeSeconds: Int? = nil,
        recording: Bool,
        routingNumber: String? = nil,
        session: CallSessionResponse? = nil,
        settings: CallSettingsResponse,
        startsAt: Date? = nil,
        team: String? = nil,
        thumbnails: ThumbnailResponse? = nil,
        transcribing: Bool,
        translating: Bool,
        type: String,
        updatedAt: Date
    ) {
        self.backstage = backstage
        self.blockedUserIds = blockedUserIds
        self.captioning = captioning
        self.cid = cid
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.currentSessionId = currentSessionId
        self.custom = custom
        self.egress = egress
        self.endedAt = endedAt
        self.id = id
        self.ingress = ingress
        self.joinAheadTimeSeconds = joinAheadTimeSeconds
        self.recording = recording
        self.routingNumber = routingNumber
        self.session = session
        self.settings = settings
        self.startsAt = startsAt
        self.team = team
        self.thumbnails = thumbnails
        self.transcribing = transcribing
        self.translating = translating
        self.type = type
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.backstage = try container.decode(Bool.self, forKey: .backstage)
        self.blockedUserIds = try container.decode([String].self, forKey: .blockedUserIds)
        self.captioning = try container.decode(Bool.self, forKey: .captioning)
        self.cid = try container.decode(String.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.createdBy = try container.decode(UserResponse.self, forKey: .createdBy)
        self.currentSessionId = try container.decode(String.self, forKey: .currentSessionId)
        self.custom = try container.decode([String: RawJSON].self, forKey: .custom)
        self.egress = try container.decode(EgressResponse.self, forKey: .egress)
        self.endedAt = try container.decodeIfPresent(Date.self, forKey: .endedAt)
        self.id = try container.decode(String.self, forKey: .id)
        self.ingress = try container.decode(CallIngressResponse.self, forKey: .ingress)
        self.joinAheadTimeSeconds = try container.decodeIfPresent(Int.self, forKey: .joinAheadTimeSeconds)
        self.recording = try container.decode(Bool.self, forKey: .recording)
        self.routingNumber = try container.decodeIfPresent(String.self, forKey: .routingNumber)
        self.session = try container.decodeIfPresent(CallSessionResponse.self, forKey: .session)
        self.settings = try container.decode(CallSettingsResponse.self, forKey: .settings)
        self.startsAt = try container.decodeIfPresent(Date.self, forKey: .startsAt)
        self.team = try container.decodeIfPresent(String.self, forKey: .team)
        self.thumbnails = try container.decodeIfPresent(ThumbnailResponse.self, forKey: .thumbnails)
        self.transcribing = try container.decode(Bool.self, forKey: .transcribing)
        self.translating = try container.decode(Bool.self, forKey: .translating)
        self.type = try container.decode(String.self, forKey: .type)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

extension CallResponse: Hashable {
    public static func == (lhs: CallResponse, rhs: CallResponse) -> Bool {
        lhs.backstage == rhs.backstage &&
            lhs.blockedUserIds == rhs.blockedUserIds &&
            lhs.captioning == rhs.captioning &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.createdBy == rhs.createdBy &&
            lhs.currentSessionId == rhs.currentSessionId &&
            lhs.custom == rhs.custom &&
            lhs.egress == rhs.egress &&
            lhs.endedAt == rhs.endedAt &&
            lhs.id == rhs.id &&
            lhs.ingress == rhs.ingress &&
            lhs.joinAheadTimeSeconds == rhs.joinAheadTimeSeconds &&
            lhs.recording == rhs.recording &&
            lhs.routingNumber == rhs.routingNumber &&
            lhs.session == rhs.session &&
            lhs.settings == rhs.settings &&
            lhs.startsAt == rhs.startsAt &&
            lhs.team == rhs.team &&
            lhs.thumbnails == rhs.thumbnails &&
            lhs.transcribing == rhs.transcribing &&
            lhs.translating == rhs.translating &&
            lhs.type == rhs.type &&
            lhs.updatedAt == rhs.updatedAt
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(backstage)
        hasher.combine(blockedUserIds)
        hasher.combine(captioning)
        hasher.combine(cid)
        hasher.combine(createdAt)
        hasher.combine(createdBy)
        hasher.combine(currentSessionId)
        hasher.combine(custom)
        hasher.combine(egress)
        hasher.combine(endedAt)
        hasher.combine(id)
        hasher.combine(ingress)
        hasher.combine(joinAheadTimeSeconds)
        hasher.combine(recording)
        hasher.combine(routingNumber)
        hasher.combine(session)
        hasher.combine(settings)
        hasher.combine(startsAt)
        hasher.combine(team)
        hasher.combine(thumbnails)
        hasher.combine(transcribing)
        hasher.combine(translating)
        hasher.combine(type)
        hasher.combine(updatedAt)
    }
}
