//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var backstage: Bool
    public var blockedUserIds: [String]
    public var captioning: Bool
    public var cid: String
    public var createdAt: Date
    public var createdBy: UserResponse
    public var currentSessionId: String
    public var custom: [String: RawJSON]
    public var egress: EgressResponse
    public var endedAt: Date?
    public var id: String
    public var ingress: CallIngressResponse
    public var joinAheadTimeSeconds: Int?
    public var recording: Bool
    public var session: CallSessionResponse?
    public var settings: CallSettingsResponse
    public var startsAt: Date?
    public var team: String?
    public var thumbnails: ThumbnailResponse?
    public var transcribing: Bool
    public var type: String
    public var updatedAt: Date

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
        session: CallSessionResponse? = nil,
        settings: CallSettingsResponse,
        startsAt: Date? = nil,
        team: String? = nil,
        thumbnails: ThumbnailResponse? = nil,
        transcribing: Bool,
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
        self.session = session
        self.settings = settings
        self.startsAt = startsAt
        self.team = team
        self.thumbnails = thumbnails
        self.transcribing = transcribing
        self.type = type
        self.updatedAt = updatedAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case backstage
        case blockedUserIds = "blocked_user_ids"
        case captioning
        case cid
        case createdAt = "created_at"
        case createdBy = "created_by"
        case currentSessionId = "current_session_id"
        case custom
        case egress
        case endedAt = "ended_at"
        case id
        case ingress
        case joinAheadTimeSeconds = "join_ahead_time_seconds"
        case recording
        case session
        case settings
        case startsAt = "starts_at"
        case team
        case thumbnails
        case transcribing
        case type
        case updatedAt = "updated_at"
    }
    
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
            lhs.session == rhs.session &&
            lhs.settings == rhs.settings &&
            lhs.startsAt == rhs.startsAt &&
            lhs.team == rhs.team &&
            lhs.thumbnails == rhs.thumbnails &&
            lhs.transcribing == rhs.transcribing &&
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
        hasher.combine(session)
        hasher.combine(settings)
        hasher.combine(startsAt)
        hasher.combine(team)
        hasher.combine(thumbnails)
        hasher.combine(transcribing)
        hasher.combine(type)
        hasher.combine(updatedAt)
    }
}
