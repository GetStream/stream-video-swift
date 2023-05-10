//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public struct CallData: @unchecked Sendable {
    public let callCid: String
    public var members: [User]
    public var blockedUsers: [User]
    public let createdAt: Date
    public var backstage: Bool
    public var broadcasting: Bool
    public var endedAt: Date?
    public var recording: Bool
    public var startsAt: Date?
    public var updatedAt: Date
    public var hlsPlaylistUrl: String
    public var customData: [String: Any]
}

extension CallData {
    mutating func applyUpdates(from callResponse: CallResponse) {
        self.backstage = callResponse.backstage
        self.broadcasting = callResponse.broadcasting
        self.endedAt = callResponse.endedAt
        self.recording = callResponse.recording
        self.startsAt = callResponse.startsAt
        self.updatedAt = callResponse.updatedAt
        self.hlsPlaylistUrl = callResponse.hlsPlaylistUrl
    }
}
