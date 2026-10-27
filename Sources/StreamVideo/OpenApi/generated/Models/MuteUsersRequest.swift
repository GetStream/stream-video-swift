//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class MuteUsersRequest: @unchecked Sendable, Codable, JSONEncodable {
    public var audio: Bool?
    public var muteAllUsers: Bool?
    public var screenshare: Bool?
    public var screenshareAudio: Bool?
    public var userIds: [String]?
    public var video: Bool?

    public init(
        audio: Bool? = nil,
        muteAllUsers: Bool? = nil,
        screenshare: Bool? = nil,
        screenshareAudio: Bool? = nil,
        userIds: [String]? = nil,
        video: Bool? = nil
    ) {
        self.audio = audio
        self.muteAllUsers = muteAllUsers
        self.screenshare = screenshare
        self.screenshareAudio = screenshareAudio
        self.userIds = userIds
        self.video = video
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.audio = try container.decodeIfPresent(Bool.self, forKey: .audio)
        self.muteAllUsers = try container.decodeIfPresent(Bool.self, forKey: .muteAllUsers)
        self.screenshare = try container.decodeIfPresent(Bool.self, forKey: .screenshare)
        self.screenshareAudio = try container.decodeIfPresent(Bool.self, forKey: .screenshareAudio)
        self.userIds = try container.decodeIfPresent([String].self, forKey: .userIds)
        self.video = try container.decodeIfPresent(Bool.self, forKey: .video)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(audio, forKey: .audio)
        try container.encodeIfPresent(muteAllUsers, forKey: .muteAllUsers)
        try container.encodeIfPresent(screenshare, forKey: .screenshare)
        try container.encodeIfPresent(screenshareAudio, forKey: .screenshareAudio)
        try container.encodeIfPresent(userIds, forKey: .userIds)
        try container.encodeIfPresent(video, forKey: .video)
    }
}

extension MuteUsersRequest: Hashable {
    public static func == (lhs: MuteUsersRequest, rhs: MuteUsersRequest) -> Bool {
        lhs.audio == rhs.audio &&
            lhs.muteAllUsers == rhs.muteAllUsers &&
            lhs.screenshare == rhs.screenshare &&
            lhs.screenshareAudio == rhs.screenshareAudio &&
            lhs.userIds == rhs.userIds &&
            lhs.video == rhs.video
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(audio)
        hasher.combine(muteAllUsers)
        hasher.combine(screenshare)
        hasher.combine(screenshareAudio)
        hasher.combine(userIds)
        hasher.combine(video)
    }
}
