//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class GetOrCreateCallRequest: @unchecked Sendable, Encodable, JSONEncodable {
    /// CallRequest is the payload for creating a call.
    public var data: CallRequest?
    public var membersLimit: Int?
    /// if provided it sends a notification event to the members for this call
    public var notify: Bool?
    /// if provided it sends a ring event to the members for this call
    public var ring: Bool?
    public var video: Bool?

    public init(data: CallRequest? = nil, membersLimit: Int? = nil, notify: Bool? = nil, ring: Bool? = nil, video: Bool? = nil) {
        self.data = data
        self.membersLimit = membersLimit
        self.notify = notify
        self.ring = ring
        self.video = video
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(membersLimit, forKey: .membersLimit)
        try container.encodeIfPresent(notify, forKey: .notify)
        try container.encodeIfPresent(ring, forKey: .ring)
        try container.encodeIfPresent(video, forKey: .video)
    }
}

extension GetOrCreateCallRequest: Hashable {
    public static func == (lhs: GetOrCreateCallRequest, rhs: GetOrCreateCallRequest) -> Bool {
        lhs.data == rhs.data &&
            lhs.membersLimit == rhs.membersLimit &&
            lhs.notify == rhs.notify &&
            lhs.ring == rhs.ring &&
            lhs.video == rhs.video
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(data)
        hasher.combine(membersLimit)
        hasher.combine(notify)
        hasher.combine(ring)
        hasher.combine(video)
    }
}
