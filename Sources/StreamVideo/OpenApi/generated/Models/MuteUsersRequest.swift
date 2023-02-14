//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct MuteUsersRequest: Codable, JSONEncodable, Hashable {

    internal var audio: Bool?
    internal var muteAllUsers: Bool?
    internal var screenshare: Bool?
    internal var userIds: [String]?
    internal var video: Bool?

    internal init(
        audio: Bool? = nil,
        muteAllUsers: Bool? = nil,
        screenshare: Bool? = nil,
        userIds: [String]? = nil,
        video: Bool? = nil
    ) {
        self.audio = audio
        self.muteAllUsers = muteAllUsers
        self.screenshare = screenshare
        self.userIds = userIds
        self.video = video
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case audio
        case muteAllUsers = "mute_all_users"
        case screenshare
        case userIds = "user_ids"
        case video
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(audio, forKey: .audio)
        try container.encodeIfPresent(muteAllUsers, forKey: .muteAllUsers)
        try container.encodeIfPresent(screenshare, forKey: .screenshare)
        try container.encodeIfPresent(userIds, forKey: .userIds)
        try container.encodeIfPresent(video, forKey: .video)
    }
}
