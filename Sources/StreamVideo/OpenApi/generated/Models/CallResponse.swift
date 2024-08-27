//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var backstage: Bool
    public var blockedUserIds: [String]
    public var cid: String
    public var createdAt: Date
    public var createdBy: UserResponse
    public var currentSessionId: String
    public var custom: [String: RawJSON]
    public var egress: EgressResponse
    public var endedAt: Date? = nil
    public var id: String
    public var ingress: CallIngressResponse
    public var joinAheadTimeSeconds: Int? = nil
    public var recording: Bool
    public var session: CallSessionResponse? = nil
    public var settings: CallSettingsResponse
    public var startsAt: Date? = nil
    public var team: String? = nil
    public var thumbnails: ThumbnailResponse? = nil
    public var transcribing: Bool
    public var type: String
    public var updatedAt: Date

    public init(
        backstage: Bool,
        blockedUserIds: [String],
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
}
