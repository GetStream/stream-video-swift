//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class StopLiveRequest: Sendable, Encodable, JSONEncodable {
    public let continueClosedCaption: Bool?
    public let continueHls: Bool?
    public let continueRecording: Bool?
    public let continueRtmpBroadcasts: Bool?
    public let continueTranscription: Bool?

    public init(
        continueClosedCaption: Bool? = nil,
        continueHls: Bool? = nil,
        continueRecording: Bool? = nil,
        continueRtmpBroadcasts: Bool? = nil,
        continueTranscription: Bool? = nil
    ) {
        self.continueClosedCaption = continueClosedCaption
        self.continueHls = continueHls
        self.continueRecording = continueRecording
        self.continueRtmpBroadcasts = continueRtmpBroadcasts
        self.continueTranscription = continueTranscription
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(continueClosedCaption, forKey: .continueClosedCaption)
        try container.encodeIfPresent(continueHls, forKey: .continueHls)
        try container.encodeIfPresent(continueRecording, forKey: .continueRecording)
        try container.encodeIfPresent(continueRtmpBroadcasts, forKey: .continueRtmpBroadcasts)
        try container.encodeIfPresent(continueTranscription, forKey: .continueTranscription)
    }
}

extension StopLiveRequest: Hashable {
    public static func == (lhs: StopLiveRequest, rhs: StopLiveRequest) -> Bool {
        lhs.continueClosedCaption == rhs.continueClosedCaption &&
            lhs.continueHls == rhs.continueHls &&
            lhs.continueRecording == rhs.continueRecording &&
            lhs.continueRtmpBroadcasts == rhs.continueRtmpBroadcasts &&
            lhs.continueTranscription == rhs.continueTranscription
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(continueClosedCaption)
        hasher.combine(continueHls)
        hasher.combine(continueRecording)
        hasher.combine(continueRtmpBroadcasts)
        hasher.combine(continueTranscription)
    }
}
