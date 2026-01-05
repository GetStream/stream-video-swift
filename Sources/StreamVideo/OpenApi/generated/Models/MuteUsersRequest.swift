//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class MuteUsersRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case audio
        case muteAllUsers = "mute_all_users"
        case screenshare
        case screenshareAudio = "screenshare_audio"
        case userIds = "user_ids"
        case video
    }
    
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
