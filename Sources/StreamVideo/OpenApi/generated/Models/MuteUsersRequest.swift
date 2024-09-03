//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct MuteUsersRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var audio: Bool? = nil
    public var muteAllUsers: Bool? = nil
    public var screenshare: Bool? = nil
    public var screenshareAudio: Bool? = nil
    public var userIds: [String]? = nil
    public var video: Bool? = nil

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
}
