//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class StopLiveRequest: @unchecked Sendable, Codable, JSONEncodable {
    public var continueClosedCaption: Bool?
    public var continueHls: Bool?
    public var continueRecording: Bool?
    public var continueRtmpBroadcasts: Bool?
    public var continueTranscription: Bool?

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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.continueClosedCaption = try container.decodeIfPresent(Bool.self, forKey: .continueClosedCaption)
        self.continueHls = try container.decodeIfPresent(Bool.self, forKey: .continueHls)
        self.continueRecording = try container.decodeIfPresent(Bool.self, forKey: .continueRecording)
        self.continueRtmpBroadcasts = try container.decodeIfPresent(Bool.self, forKey: .continueRtmpBroadcasts)
        self.continueTranscription = try container.decodeIfPresent(Bool.self, forKey: .continueTranscription)
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
